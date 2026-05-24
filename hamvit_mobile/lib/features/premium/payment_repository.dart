import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_provider.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(supabaseClientProvider));
});

class PaymentRepository {
  final SupabaseClient? _client;
  PaymentRepository(this._client);

  Future<Map<String, dynamic>> createMercadoPagoPayment({
    required String method,
    String? couponCode,
    String? cpf,
  }) async {
    final client = _client;
    if (client == null) return {'ok': false, 'error': 'client_unavailable'};

    final response = await client.functions.invoke(
      'create-mercado-pago-payment',
      body: {
        'method': method,
        'coupon_code': couponCode,
        'cpf': cpf,
      },
    );

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    return {'ok': false, 'error': 'invalid_backend_response'};
  }

  Future<Map<String, dynamic>?> loadLatestPayment() async {
    final client = _client;
    if (client == null) return null;
    final user = client.auth.currentUser;
    if (user == null) return null;

    final row = await client
        .from('payments')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return row;
  }

  Future<bool> hasActivePremiumEntitlement() async {
    final client = _client;
    if (client == null) return false;
    final user = client.auth.currentUser;
    if (user == null) return false;

    final ent = await client
        .from('user_entitlements')
        .select('id')
        .eq('user_id', user.id)
        .eq('active', true)
        .or('entitlement_key.eq.premium_lifetime,plan.eq.premium_lifetime')
        .limit(1)
        .maybeSingle();

    return ent != null;
  }
}
