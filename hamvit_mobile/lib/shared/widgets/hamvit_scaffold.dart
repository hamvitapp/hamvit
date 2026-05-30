import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/dashboard/domain/dashboard_metrics_service.dart';
import '../../features/evolution/evolution_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/today_page.dart';
import '../../features/home/providers/home_dashboard_provider.dart';
import '../../features/settings/profile_page.dart';
import '../../theme/hamvit_colors.dart';
import 'hamvit_bottom_nav.dart';
import 'hamvit_components.dart';
import 'hamvit_side_drawer.dart';

class HamvitScaffold extends ConsumerStatefulWidget {
  final int initialIndex;
  const HamvitScaffold({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HamvitScaffold> createState() => _HamvitScaffoldState();
}

class _HamvitScaffoldState extends ConsumerState<HamvitScaffold> {
  static const _pendingPhotoFlowKey = 'hamvit_pending_profile_photo_flow';
  late int index;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _prefetchedUserId;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    _handlePendingProfilePhotoFlow();
  }

  Future<void> _handlePendingProfilePhotoFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_pendingPhotoFlowKey) ?? false;
    if (!pending || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    if (GoRouterState.of(context).matchedLocation != '/profile/edit') {
      context.push('/profile/edit');
    }
  }

  void _warmupCoreData(String? userId) {
    if (userId == null || userId.isEmpty) return;
    if (_prefetchedUserId == userId) return;
    _prefetchedUserId = userId;
    Future<void>.delayed(const Duration(milliseconds: 120), () async {
      if (!mounted) return;
      try {
        await ref.read(homeDashboardProvider.future);
      } catch (_) {}
      try {
        await ref.read(dashboardSnapshotProvider.future);
      } catch (_) {}
      try {
        await ref.read(evolutionDashboardProvider.future);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final auth = ref.read(authStateProvider.notifier);
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(currentProfileProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final isAdmin = ref.watch(isAdminProvider);
    if (authState.status == AuthStatus.authenticated) {
      _warmupCoreData(user?.id);
    }

    final pages = [
      TodayPage(isPremium: isPremium),
      const DashboardPage(),
      ProfilePage(name: profile?.displayName, isPremium: isPremium, onLogout: () => auth.logout()),
    ];

    final titles = ['Hoje', 'Dashboard', 'Perfil'];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(titles[index]),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [HamvitColors.primaryDark, HamvitColors.primaryNavy],
            ),
          ),
        ),
      ),
      drawerScrimColor: Colors.black.withValues(alpha: 0.35),
      drawer: HamvitSideDrawer(
        isPremium: isPremium,
        isAdmin: isAdmin,
        userName: profile?.displayName ?? user?.email,
        photoUrl: profile?.photoUrl,
        onLogout: () => auth.logout(),
        onReturnFromDrawerRoute: () {
          if (!mounted) return;
          Future<void>.delayed(const Duration(milliseconds: 60), () {
            if (!mounted) return;
            _scaffoldKey.currentState?.openDrawer();
          });
        },
      ),
      body: authState.status == AuthStatus.loading
          ? const HamvitLoading()
          : authState.status == AuthStatus.error
              ? HamvitErrorState(message: authState.errorMessage ?? 'Erro ao carregar sessão')
              : Column(
                  children: [
                    if (!isPremium)
                      Container(
                        width: double.infinity,
                        color: HamvitColors.accentGreen.withValues(alpha: 0.12),
                        padding: const EdgeInsets.all(10),
                        child: const Text('Plano Free ativo. Premium Vitalício: sem mensalidade, sem anuncios. Evolua no seu ritmo.'),
                      ),
                    Expanded(
                      child: pages[index],
                    ),
                  ],
                ),
      bottomNavigationBar: HamvitBottomNav(currentIndex: index, onTap: (v) => setState(() => index = v)),
    );
  }
}
