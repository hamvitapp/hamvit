import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_provider.dart';
import 'payment_repository.dart';

final premiumServiceProvider = Provider<PremiumService>((ref) {
  return PremiumService(ref.watch(supabaseClientProvider));
});

class PremiumService {
  final SupabaseClient? _client;
  final PaymentRepository? _paymentRepository;
  PremiumService(this._client) : _paymentRepository = _client == null ? null : PaymentRepository(_client);

  Future<bool> isPremium() async {
    final client = _client;
    if (client == null) return false;
    final user = client.auth.currentUser;
    if (user == null) return false;
    final ent = await client
        .from('user_entitlements')
      .select('entitlement_key, plan, active')
        .eq('user_id', user.id)
      .or('entitlement_key.eq.premium_lifetime,plan.eq.premium_lifetime')
        .eq('active', true)
        .maybeSingle();
    return ent != null;
  }

  Future<Map<String, dynamic>> createPayment({required double amountBrl, String? coupon}) async {
    final repository = _paymentRepository;
    if (repository == null) return {'ok': false, 'error': 'client_unavailable'};
    return repository.createMercadoPagoPayment(
      method: 'pix',
      couponCode: coupon,
    );
  }
}
