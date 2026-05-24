import '../../features/auth/domain/auth_state.dart';

class PremiumRouteGuard {
  const PremiumRouteGuard._();

  static String? redirectIfBlocked({
    required String location,
    required AuthStatus status,
    required bool isPremium,
  }) {
    if (status != AuthStatus.authenticated) return null;
    if (_premiumLocations.contains(location) && !isPremium) {
      return '/premium';
    }
    return null;
  }

  static const Set<String> _premiumLocations = {
    '/food-ai',
    '/meal-suggestions',
    '/reports/weekly',
    '/reports/monthly',
    '/reports/professional',
    '/reports/pdf',
    '/advanced-analytics',
  };
}

class AdminRouteGuard {
  const AdminRouteGuard._();

  static String? redirectIfBlocked({
    required String location,
    required AuthStatus status,
    required bool isAdmin,
  }) {
    if (status != AuthStatus.authenticated) return null;
    if (_adminLocations.contains(location) && !isAdmin) {
      return '/home';
    }
    return null;
  }

  static const Set<String> _adminLocations = {'/admin'};
}
