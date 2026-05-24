import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/premium/route_guards.dart';
import '../features/activities/activities_page.dart';
import '../features/admin_shortcuts/admin_shortcuts_page.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/onboarding/presentation/activity_profile_flow.dart';
import '../features/onboarding/presentation/food_preferences_flow.dart';
import '../features/onboarding/presentation/hydration_flow.dart';
import '../features/onboarding/presentation/sleep_flow.dart';
import '../features/onboarding/presentation/general_profile_flow.dart';
import '../features/onboarding/presentation/objectives_summary_screen.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/meal_recommendations/meal_recommendations_page.dart';
import '../features/menu/drawer_subpages.dart';
import '../features/onboarding/presentation/my_profile_hub_screen.dart';
import '../features/habits/habits_page.dart';
import '../features/premium/advanced_analytics_screen.dart';
import '../features/premium/premium_page.dart';
import '../features/reports/analytics_screen.dart';
import '../features/reports/reports_pdf_screen.dart';
import '../features/reports/reports_period_screen.dart';
import '../features/reports/reports_page.dart';
import '../features/settings/settings_screen.dart';
import '../shared/widgets/hamvit_back_app_bar.dart';
import '../shared/widgets/hamvit_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final repo = ref.watch(authRepositoryProvider);

  final publicRoutes = <String>{
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
  };

  final authenticatedRoutes = <String>{
    '/home',
    '/habits',
    '/nutrition',
    '/progress',
    '/profile',
    '/settings',
    '/activities',
    '/reports',
    '/welcome',
    '/meu-perfil',
    '/onboarding',
    '/onboarding/general',
    '/onboarding/objectives',
    '/onboarding/food',
    '/onboarding/activity',
    '/onboarding/sleep',
    '/onboarding/hydration',
    '/drawer/objectives',
    '/drawer/food',
    '/drawer/activity',
    '/drawer/habits',
    '/drawer/sleep',
    '/drawer/hydration',
    '/drawer/subitem',
    '/drawer/admin',
  };

  final premiumRoutes = <String>{
    '/food-ai',
    '/meal-suggestions',
    '/reports/weekly',
    '/reports/monthly',
    '/reports/professional',
    '/reports/pdf',
    '/advanced-analytics',
  };

  final adminRoutes = <String>{'/admin'};

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(repo.authStateChanges),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isPublic = publicRoutes.contains(location);
      final isAuthenticatedArea =
          authenticatedRoutes.contains(location) || premiumRoutes.contains(location) || adminRoutes.contains(location);

      if (authState.status == AuthStatus.initial || authState.status == AuthStatus.loading) {
        return null;
      }

      if (authState.status == AuthStatus.unauthenticated) {
        if (isAuthenticatedArea || location == '/' || location == '/home') {
          return '/login';
        }
        return null;
      }

      if (authState.status == AuthStatus.authenticated) {
        if (isPublic || location == '/') return '/home';

        final premiumRedirect = PremiumRouteGuard.redirectIfBlocked(
          location: location,
          status: authState.status,
          isPremium: authState.isPremium,
        );
        if (premiumRedirect != null) return premiumRedirect;

        final adminRedirect = AdminRouteGuard.redirectIfBlocked(
          location: location,
          status: authState.status,
          isAdmin: authState.isAdmin,
        );
        if (adminRedirect != null) return adminRedirect;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/reset-password', builder: (context, state) => const ResetPasswordScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/onboarding/general', builder: (context, state) => const GeneralProfileFlow()),
      GoRoute(
        path: '/onboarding/objectives',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Objetivos'),
          body: const ObjectivesSummaryScreen(),
        ),
      ),
      GoRoute(path: '/onboarding/food', builder: (context, state) => const FoodPreferencesFlow()),
      GoRoute(path: '/onboarding/activity', builder: (context, state) => const ActivityProfileFlow()),
      GoRoute(path: '/onboarding/sleep', builder: (context, state) => const SleepFlow()),
      GoRoute(path: '/onboarding/hydration', builder: (context, state) => const HydrationFlow()),
      GoRoute(
        path: '/drawer/objectives',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Objetivos'),
          body: const ObjectivesSummaryScreen(),
        ),
      ),
      GoRoute(
        path: '/drawer/food',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Alimentação'),
          body: const FoodPreferencesFlow(showAppBar: false),
        ),
      ),
      GoRoute(
        path: '/drawer/activity',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Atividade Física'),
          body: const ActivityProfileFlow(showAppBar: false),
        ),
      ),
      GoRoute(
        path: '/drawer/habits',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Hábitos'),
          body: const HabitsPage(),
        ),
      ),
      GoRoute(
        path: '/drawer/sleep',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Sono'),
          body: const SleepFlow(showAppBar: false),
        ),
      ),
      GoRoute(
        path: '/drawer/hydration',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Preferências'),
          body: const HydrationFlow(showAppBar: false),
        ),
      ),
      GoRoute(
        path: '/drawer/subitem',
        builder: (context, state) {
          final type = state.extra is DrawerSubItemType ? state.extra! as DrawerSubItemType : DrawerSubItemType.supportHelp;
          return Scaffold(
            appBar: hamvitBackAppBar(context, title: drawerSubItemTitle(type)),
            body: DrawerSubItemPage(type: type, isPremium: ref.read(isPremiumProvider)),
          );
        },
      ),
      GoRoute(
        path: '/drawer/admin',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Admin'),
          body: const AdminShortcutsPage(),
        ),
      ),
      GoRoute(
        path: '/meu-perfil',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Meu Perfil'),
          body: const MyProfileHubScreen(),
        ),
      ),

      GoRoute(path: '/home', builder: (context, state) => const HamvitScaffold(initialIndex: 0)),
      GoRoute(path: '/habits', builder: (context, state) => const HamvitScaffold(initialIndex: 1)),
      GoRoute(path: '/nutrition', builder: (context, state) => const HamvitScaffold(initialIndex: 2)),
      GoRoute(path: '/progress', builder: (context, state) => const HamvitScaffold(initialIndex: 3)),
      GoRoute(path: '/profile', builder: (context, state) => const HamvitScaffold(initialIndex: 4)),

      GoRoute(
        path: '/settings',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Configurações'),
          body: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/activities',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Atividades'),
          body: const ActivitiesPage(),
        ),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Relatórios'),
          body: ReportsPage(isPremium: ref.read(isPremiumProvider)),
        ),
      ),
      GoRoute(
        path: '/reports/weekly',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Relatório Semanal'),
          body: ReportsPeriodScreen(reportType: 'weekly', isPremium: ref.read(isPremiumProvider)),
        ),
      ),
      GoRoute(
        path: '/reports/monthly',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Relatório Mensal'),
          body: ReportsPeriodScreen(reportType: 'monthly', isPremium: ref.read(isPremiumProvider)),
        ),
      ),
      GoRoute(
        path: '/reports/professional',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Relatório Profissional'),
          body: ReportsPeriodScreen(reportType: 'professional', isPremium: ref.read(isPremiumProvider)),
        ),
      ),
      GoRoute(
        path: '/reports/pdf',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Exportar PDF'),
          body: ReportsPdfScreen(isPremium: ref.read(isPremiumProvider)),
        ),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Analytics'),
          body: AnalyticsScreen(isPremium: ref.read(isPremiumProvider)),
        ),
      ),

      GoRoute(
        path: '/premium',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Premium'),
          body: const PremiumPage(),
        ),
      ),
      GoRoute(path: '/food-ai', builder: (context, state) => const HamvitScaffold(initialIndex: 2)),
      GoRoute(
        path: '/meal-suggestions',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Sugestões Premium'),
          body: MealRecommendationsPage(isPremium: ref.read(isPremiumProvider)),
        ),
      ),
      GoRoute(
        path: '/advanced-analytics',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Analytics Avançado'),
          body: AdvancedAnalyticsScreen(isPremium: ref.read(isPremiumProvider)),
        ),
      ),

      GoRoute(
        path: '/admin',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Admin'),
          body: const AdminShortcutsPage(),
        ),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
