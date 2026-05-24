import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_state.dart';

class AuthRepository {
  final SupabaseClient? _client;
  AuthRepository(this._client);

  SupabaseClient? get client => _client;

  Stream<AuthState> get authStateChanges {
    final client = _client;
    if (client == null) return const Stream.empty();
    return client.auth.onAuthStateChange;
  }

  Session? get currentSession => _client?.auth.currentSession;

  User? get currentUser => _client?.auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    final client = _client;
    if (client == null) throw Exception('Supabase indisponivel');
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String name, required String email, required String password}) async {
    final client = _client;
    if (client == null) throw Exception('Supabase indisponivel');
    await client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': name},
    );
  }

  Future<void> recoverPassword({required String email}) async {
    final client = _client;
    if (client == null) throw Exception('Supabase indisponivel');
    await client.auth.resetPasswordForEmail(email);
  }

  Future<void> resetPassword({required String newPassword}) async {
    final client = _client;
    if (client == null) throw Exception('Supabase indisponivel');
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    await client.auth.signOut();
  }

  Future<AppProfile> ensureProfile(User user, {String? fallbackName}) async {
    final client = _client;
    if (client == null) throw Exception('Supabase indisponivel');

    final existing = await client
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

    if (existing != null) {
      final needsUserIdBackfill = existing['user_id'] == null;
      final needsDisplayName = (existing['display_name'] == null || (existing['display_name'] as String).isEmpty) &&
          fallbackName != null &&
          fallbackName.trim().isNotEmpty;

      if (needsUserIdBackfill || needsDisplayName) {
        final payload = <String, dynamic>{};
        if (needsUserIdBackfill) payload['user_id'] = user.id;
        if (needsDisplayName) payload['display_name'] = fallbackName.trim();
        await client.from('profiles').update(payload).eq('id', user.id);
        final refreshed = await client.from('profiles').select('*').eq('id', user.id).single();
        return AppProfile.fromMap(refreshed);
      }

      return AppProfile.fromMap(existing);
    }

    final inserted = await client
        .from('profiles')
        .insert({
          'id': user.id,
          'user_id': user.id,
          'display_name': (fallbackName ?? user.email?.split('@').first ?? 'Usuario HAMVIT').trim(),
          'full_name': (fallbackName ?? user.email?.split('@').first ?? 'Usuario HAMVIT').trim(),
          'role': 'user',
          'plan': 'free',
          'premium_active': false,
          'onboarding_completed': false,
        })
        .select('*')
        .single();

    return AppProfile.fromMap(inserted);
  }

  Future<List<AppEntitlement>> loadEntitlements(String userId) async {
    final client = _client;
    if (client == null) return const [];

    final rows = await client
        .from('user_entitlements')
        .select('*')
        .eq('user_id', userId)
        .eq('active', true);

    return List<Map<String, dynamic>>.from(rows)
        .map(AppEntitlement.fromMap)
        .toList();
  }

  Future<void> completeOnboarding(String userId) async {
    final client = _client;
    if (client == null) return;
    await client.from('profiles').update({'onboarding_completed': true}).eq('id', userId);
  }
}
