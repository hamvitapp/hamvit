import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers/auth_provider.dart';
import 'payment_repository.dart';

class PremiumUiState {
  final bool loading;
  final String status;
  final String? message;
  final String? paymentId;
  final String? pixCode;
  final String? pixQrBase64;
  final String? checkoutUrl;
  final bool isPremium;

  const PremiumUiState({
    this.loading = false,
    this.status = 'idle',
    this.message,
    this.paymentId,
    this.pixCode,
    this.pixQrBase64,
    this.checkoutUrl,
    this.isPremium = false,
  });

  PremiumUiState copyWith({
    bool? loading,
    String? status,
    String? message,
    String? paymentId,
    String? pixCode,
    String? pixQrBase64,
    String? checkoutUrl,
    bool? isPremium,
  }) {
    return PremiumUiState(
      loading: loading ?? this.loading,
      status: status ?? this.status,
      message: message,
      paymentId: paymentId ?? this.paymentId,
      pixCode: pixCode ?? this.pixCode,
      pixQrBase64: pixQrBase64 ?? this.pixQrBase64,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}

final premiumControllerProvider = StateNotifierProvider<PremiumController, PremiumUiState>((ref) {
  return PremiumController(ref);
});

class PremiumController extends StateNotifier<PremiumUiState> {
  final Ref _ref;
  PremiumController(this._ref) : super(const PremiumUiState());

  PaymentRepository get _repo => _ref.read(paymentRepositoryProvider);

  Future<void> initialize() async {
    final premium = await _repo.hasActivePremiumEntitlement();
    state = state.copyWith(isPremium: premium, status: premium ? 'approved' : state.status);
  }

  Future<void> createPayment({required String method, String? couponCode, String? cpf}) async {
    state = state.copyWith(loading: true, message: null, status: 'pending');

    try {
      final result = await _repo.createMercadoPagoPayment(
        method: method,
        couponCode: couponCode,
        cpf: cpf,
      );

      if (result['ok'] != true) {
        state = state.copyWith(
          loading: false,
          status: 'rejected',
          message: result['error']?.toString() ?? 'Falha ao criar pagamento.',
        );
        return;
      }

      final payment = (result['payment'] as Map<String, dynamic>? ?? {});
      final pix = (result['pix'] as Map<String, dynamic>? ?? {});
      final checkout = (result['checkout'] as Map<String, dynamic>? ?? {});
      final paymentStatus = payment['status']?.toString() ?? 'pending';

      state = state.copyWith(
        loading: false,
        status: paymentStatus,
        message: paymentStatus == 'approved'
            ? 'Pagamento aprovado e premium liberado.'
            : 'Pagamento criado. Conclua para liberar o Premium.',
        paymentId: payment['id']?.toString(),
        pixCode: pix['qr_code']?.toString(),
        pixQrBase64: pix['qr_code_base64']?.toString(),
        checkoutUrl: checkout['init_point']?.toString() ?? checkout['sandbox_init_point']?.toString(),
      );

      await refreshStatus();
    } catch (e) {
      state = state.copyWith(loading: false, status: 'rejected', message: e.toString());
    }
  }

  Future<void> refreshStatus() async {
    state = state.copyWith(loading: true, message: null);
    try {
      final latest = await _repo.loadLatestPayment();
      final premium = await _repo.hasActivePremiumEntitlement();
      final paymentStatus = latest?['status']?.toString() ?? state.status;

      await _ref.read(authStateProvider.notifier).bootstrap();

      state = state.copyWith(
        loading: false,
        status: premium ? 'approved' : paymentStatus,
        isPremium: premium,
        message: premium
            ? 'Premium vitalicio ativo. Recursos liberados.'
            : 'Pagamento ainda pendente. Se já pagou, águarde o webhook e tente novamente.',
      );
    } catch (e) {
      state = state.copyWith(loading: false, message: e.toString());
    }
  }
}
