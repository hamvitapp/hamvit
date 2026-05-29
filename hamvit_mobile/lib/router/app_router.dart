import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/premium/route_guards.dart';
import '../features/activities/activities_page.dart';
import '../features/activities/preferences/activity_preferences_screen.dart';
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
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/menu/drawer_subpages.dart';
import '../features/nutrition/preferences/food_preferences_screen.dart';
import '../features/profile/body_data_page.dart';
import '../features/profile/goals_page.dart';
import '../features/profile/profile_edit_screen.dart';
import '../features/onboarding/presentation/my_profile_hub_screen.dart';
import '../features/hydration/hydration_page.dart';
import '../features/habits/habits_page.dart';
import '../features/legal/privacy_policy_screen.dart';
import '../features/legal/terms_screen.dart';
import '../features/nutrition/nutrition_page.dart';
import '../features/premium/advanced_analytics_screen.dart';
import '../features/premium/premium_page.dart';
import '../features/progress/progress_page.dart';
import '../features/reports/analytics_screen.dart';
import '../features/reports/evolution_report_screen.dart';
import '../features/reports/reports_period_screen.dart';
import '../features/reports/reports_page.dart';
import '../features/reports/reports_daily_screen.dart';
import '../features/settings/accessibility/accessibility_settings_screen.dart';
import '../features/settings/account/account_settings_screen.dart';
import '../features/settings/data_export/data_export_settings_screen.dart';
import '../features/settings/notifications/notification_settings_screen.dart';
import '../features/settings/preferences_page.dart';
import '../features/settings/privacy/privacy_settings_screen.dart';
import '../features/settings/security/security_settings_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/sleep/sleep_page.dart';
import '../features/security/biometric_gate.dart';
import '../features/nutrition/screens/recipe_suggestions_screen.dart';
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
    '/dashboard',
    '/habits',
    '/nutrition',
    '/progress',
    '/profile',
    '/legal/terms',
    '/legal/privacy',
    '/settings',
    '/settings/account',
    '/settings/security',
    '/settings/notifications',
    '/settings/privacy',
    '/settings/accessibility',
    '/settings/data-export',
    '/activities',
    '/reports',
    '/reports/evolution',
    '/reports/daily',
    '/welcome',
    '/meu-perfil',
    '/onboarding',
    '/onboarding/goal',
    '/onboarding/body',
    '/onboarding/food',
    '/onboarding/activity',
    '/onboarding/sleep',
    '/onboarding/hydration',
    '/profile/goals',
    '/profile/edit',
    '/profile/body',
    '/profile/body-data',
    '/profile/food-preferences',
    '/nutrition/preferences',
    '/activities/preferences',
    '/drawer/subitem',
    '/drawer/admin',
    '/sleep',
    '/sleep/settings',
    '/hydration',
    '/hydration/settings',
    '/settings/preferences',
  };

  final premiumRoutes = <String>{
    '/food-ai',
    '/meal-suggestions',
    '/reports/weekly',
    '/reports/monthly',
    '/reports/professional',
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

      if (authState.status == AuthStatus.error) {
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
      GoRoute(path: '/onboarding/goal', builder: (context, state) => const GeneralProfileFlow()),
      GoRoute(path: '/onboarding/body', builder: (context, state) => const ActivityProfileFlow()),
      GoRoute(path: '/onboarding/food', builder: (context, state) => const FoodPreferencesFlow()),
      GoRoute(path: '/onboarding/activity', builder: (context, state) => const ActivityProfileFlow()),
      GoRoute(path: '/onboarding/sleep', builder: (context, state) => const SleepFlow()),
      GoRoute(path: '/onboarding/hydration', builder: (context, state) => const HydrationFlow()),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Editar perfil'),
          body: const ProfileEditScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/goals',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Objetivos'),
          body: const GoalsPage(),
        ),
      ),
      GoRoute(
        path: '/profile/body-data',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Dados corporais'),
          body: const HamvitBiometricGate(
            reason: 'Confirme sua biometria para acessar seus dados corporais.',
            child: BodyDataPage(),
          ),
        ),
      ),
      GoRoute(
        path: '/profile/body',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Dados corporais'),
          body: const HamvitBiometricGate(
            reason: 'Confirme sua biometria para acessar seus dados corporais.',
            child: BodyDataPage(),
          ),
        ),
      ),
      GoRoute(path: '/profile/food-preferences', builder: (context, state) => const FoodPreferencesScreen()),
      GoRoute(path: '/nutrition/preferences', builder: (context, state) => const FoodPreferencesScreen()),
      GoRoute(
        path: '/activities/preferences',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Preferencias de atividade'),
          body: const ActivityPreferencesScreen(),
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
      GoRoute(path: '/dashboard', builder: (context, state) => const HamvitScaffold(initialIndex: 1)),
      GoRoute(
        path: '/habits',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Hábitos'),
          body: const HabitsPage(),
        ),
      ),
      GoRoute(
        path: '/nutrition',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Alimentação'),
          body: NutritionPage(isPremium: ref.read(isPremiumProvider)),
        ),
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Evolução'),
          body: const ProgressPage(),
        ),
      ),
      GoRoute(path: '/profile', builder: (context, state) => const HamvitScaffold(initialIndex: 2)),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/preferences',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Preferências'),
          body: const PreferencesPage(),
        ),
      ),
      GoRoute(
        path: '/settings/account',
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/security',
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/accessibility',
        builder: (context, state) => const AccessibilitySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/data-export',
        builder: (context, state) => const DataExportSettingsScreen(),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (context, state) => TermsScreen(),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (context, state) => PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/activities',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Atividades'),
          body: const ActivitiesPage(),
        ),
      ),
      GoRoute(
        path: '/sleep',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Sono'),
          body: const SleepPage(),
        ),
      ),
      GoRoute(
        path: '/sleep/settings',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Configuracoes de sono'),
          body: const SleepPage(),
        ),
      ),
      GoRoute(
        path: '/hydration',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Hidratação'),
          body: const HydrationPage(),
        ),
      ),
      GoRoute(
        path: '/hydration/settings',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Configuracoes de hidratacao'),
          body: const HydrationPage(),
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
        path: '/reports/evolution',
        builder: (context, state) => const EvolutionReportScreen(),
      ),
      GoRoute(
        path: '/reports/daily',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Score diário'),
          body: const ReportsDailyScreen(),
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
      GoRoute(
        path: '/food-ai',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Alimentação'),
          body: NutritionPage(isPremium: ref.read(isPremiumProvider)),
        ),
      ),
      GoRoute(
        path: '/meal-suggestions',
        builder: (context, state) => Scaffold(
          appBar: hamvitBackAppBar(context, title: 'Sugestões Premium'),
          body: RecipeSuggestionsScreen(isPremium: ref.read(isPremiumProvider)),
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
