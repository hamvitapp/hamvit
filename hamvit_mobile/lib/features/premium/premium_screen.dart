import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/hamvit_components.dart';
import 'coupon_input.dart';
import 'payment_status_screen.dart';
import 'premium_controller.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  final _couponController = TextEditingController();
  final _cpfController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(premiumControllerProvider.notifier).initialize());
  }

  @override
  void dispose() {
    _couponController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(premiumControllerProvider);
    final controller = ref.read(premiumControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HamvitHeader(
          title: 'HAMVIT Premium vitalício',
          subtitle: 'Um único pagamento, sem mensalidade e sem anúncios.',
        ),
        const SizedBox(height: 12),
        const HamvitIconCard(
          assetPath: 'assets/icons/alimentacao.png',
          label: 'IA de foto da comida com revisão antes de salvar',
        ),
        const SizedBox(height: 8),
        const HamvitIconCard(
          assetPath: 'assets/icons/alimentacao.png',
          label: 'Recomendações alimentares inteligentes e personalizadas',
        ),
        const SizedBox(height: 8),
        const HamvitIconCard(
          assetPath: 'assets/icons/relatorios.png',
          label: 'Relatórios PDF, compartilhamento e analytics avançados',
        ),
        const SizedBox(height: 14),
        CouponInput(controller: _couponController),
        const SizedBox(height: 8),
        TextField(
          controller: _cpfController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'CPF para PIX (opcional)',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: state.loading
                    ? null
                    : () => controller.createPayment(
                          method: 'pix',
                          couponCode: _couponController.text.trim(),
                          cpf: _cpfController.text.trim(),
                        ),
                icon: const Icon(Icons.qr_code_2),
                label: Text(state.loading ? 'Gerando PIX...' : 'Pagar com PIX'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.loading
                    ? null
                    : () => controller.createPayment(
                          method: 'credit_card',
                          couponCode: _couponController.text.trim(),
                          cpf: _cpfController.text.trim(),
                        ),
                icon: const Icon(Icons.credit_card),
                label: const Text('Pagar com cartão'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PaymentStatusScreen(
          status: state.status,
          message: state.message,
          pixCode: state.pixCode,
          pixQrBase64: state.pixQrBase64,
          checkoutUrl: state.checkoutUrl,
          onRefresh: () => controller.refreshStatus(),
        ),
        if (state.isPremium) ...[
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('Premium ativo. Recursos desbloqueados: IA de foto, recomendações, PDF, compartilhamento e analytics.'),
            ),
          ),
        ],
      ],
    );
  }
}
