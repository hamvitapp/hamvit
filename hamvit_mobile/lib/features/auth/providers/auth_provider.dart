import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_provider.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthStateModel>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

final currentProfileProvider = Provider<AppProfile?>((ref) {
  return ref.watch(authStateProvider).profile;
});

final currentEntitlementsProvider = Provider<List<AppEntitlement>>((ref) {
  return ref.watch(authStateProvider).entitlements;
});

final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isPremium;
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAdmin;
});

class AuthNotifier extends StateNotifier<AuthStateModel> {
  final AuthRepository _repository;
  StreamSubscription<AuthState>? _subscription;

  AuthNotifier(this._repository)
      : super(const AuthStateModel(status: AuthStatus.initial)) {
    _subscription = _repository.authStateChanges.listen((_) {
      bootstrap();
    });
    bootstrap();
  }

  Future<void> bootstrap() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final session = _repository.currentSession;
      final user = _repository.currentUser;
      if (session == null || user == null) {
        state = const AuthStateModel(status: AuthStatus.unauthenticated);
        return;
      }

      final fallbackName = (user.userMetadata?['display_name'] as String?) ??
          (user.userMetadata?['name'] as String?) ??
          user.email?.split('@').first;

      final profile = await _repository.ensureProfile(user, fallbackName: fallbackName);
      final entitlements = await _repository.loadEntitlements(user.id);
      state = AuthStateModel(
        status: AuthStatus.authenticated,
        user: user,
        profile: profile,
        entitlements: entitlements,
      );
    } catch (e) {
      state = AuthStateModel(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.signIn(email: email, password: password);
      await bootstrap();
    } on AuthException catch (e) {
      state = AuthStateModel(status: AuthStatus.unauthenticated, errorMessage: e.message);
    } catch (e) {
      state = AuthStateModel(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.signUp(name: name, email: email, password: password);
      await bootstrap();
    } on AuthException catch (e) {
      state = AuthStateModel(status: AuthStatus.unauthenticated, errorMessage: e.message);
    } catch (e) {
      state = AuthStateModel(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> sendRecoveryEmail(String email) async {
    try {
      await _repository.recoverPassword(email: email);
    } on AuthException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> updatePassword(String newPassword) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.resetPassword(newPassword: newPassword);
      await bootstrap();
    } on AuthException catch (e) {
      state = AuthStateModel(status: AuthStatus.error, errorMessage: e.message);
    } catch (e) {
      state = AuthStateModel(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> completeOnboarding() async {
    final user = state.user;
    if (user == null) return;
    await _repository.completeOnboarding(user.id);
    await bootstrap();
  }

  Future<void> logout() async {
    await _repository.signOut();
    state = const AuthStateModel(status: AuthStatus.unauthenticated);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
