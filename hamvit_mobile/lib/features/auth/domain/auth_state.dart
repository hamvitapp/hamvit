import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus {
  initial,
  loading,
  unauthenticated,
  authenticated,
  needsOnboarding,
  error,
}

class AppProfile {
  final String id;
  final String userId;
  final String? displayName;
  final String? photoUrl;
  final String role;
  final String plan;
  final bool premiumActive;
  final bool onboardingCompleted;

  const AppProfile({
    required this.id,
    required this.userId,
    this.displayName,
    this.photoUrl,
    required this.role,
    required this.plan,
    required this.premiumActive,
    required this.onboardingCompleted,
  });

  factory AppProfile.fromMap(Map<String, dynamic> map) {
    return AppProfile(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? map['id'] ?? '').toString(),
      displayName: map['display_name'] as String? ?? map['full_name'] as String?,
      photoUrl: map['photo_url'] as String?,
      role: (map['role'] ?? 'user').toString(),
      plan: (map['plan'] ?? 'free').toString(),
      premiumActive: (map['premium_active'] as bool?) ?? false,
      onboardingCompleted: (map['onboarding_completed'] as bool?) ?? false,
    );
  }
}

class AppEntitlement {
  final String id;
  final String entitlementKey;
  final bool active;

  const AppEntitlement({required this.id, required this.entitlementKey, required this.active});

  factory AppEntitlement.fromMap(Map<String, dynamic> map) {
    return AppEntitlement(
      id: (map['id'] ?? '').toString(),
      entitlementKey: (map['entitlement_key'] ?? map['plan'] ?? '').toString(),
      active: (map['active'] as bool?) ?? false,
    );
  }
}

class AuthStateModel {
  final AuthStatus status;
  final User? user;
  final AppProfile? profile;
  final List<AppEntitlement> entitlements;
  final String? errorMessage;

  const AuthStateModel({
    required this.status,
    this.user,
    this.profile,
    this.entitlements = const [],
    this.errorMessage,
  });

  bool get isPremium {
    final hasEntitlement = entitlements.any(
      (e) => e.active && e.entitlementKey == 'premium_lifetime',
    );
    return hasEntitlement || profile?.premiumActive == true || profile?.plan == 'premium_lifetime';
  }

  bool get isAdmin {
    final role = profile?.role;
    return role == 'admin' || role == 'super_admin';
  }

  AuthStateModel copyWith({
    AuthStatus? status,
    User? user,
    AppProfile? profile,
    List<AppEntitlement>? entitlements,
    String? errorMessage,
  }) {
    return AuthStateModel(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      entitlements: entitlements ?? this.entitlements,
      errorMessage: errorMessage,
    );
  }
}
