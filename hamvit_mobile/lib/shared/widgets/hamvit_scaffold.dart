import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/habits/habits_page.dart';
import '../../features/home/today_page.dart';
import '../../features/nutrition/nutrition_page.dart';
import '../../features/progress/progress_page.dart';
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
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final auth = ref.read(authStateProvider.notifier);
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(currentProfileProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final isAdmin = ref.watch(isAdminProvider);

    final pages = [
      TodayPage(isPremium: isPremium),
      const DashboardPage(),
      const HabitsPage(),
      NutritionPage(isPremium: isPremium),
      const ProgressPage(),
      ProfilePage(name: profile?.displayName, isPremium: isPremium, onLogout: () => auth.logout()),
    ];

    final titles = ['Hoje', 'Dashboard', 'Hábitos', 'Alimentação', 'Evolução', 'Perfil'];

    return Scaffold(
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
        onLogout: () => auth.logout(),
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


