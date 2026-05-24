import 'dart:convert';

import 'package:flutter/material.dart';

class PaymentStatusScreen extends StatelessWidget {
  final String status;
  final String? message;
  final String? pixQrBase64;
  final String? pixCode;
  final String? checkoutUrl;
  final VoidCallback onRefresh;

  const PaymentStatusScreen({
    super.key,
    required this.status,
    required this.onRefresh,
    this.message,
    this.pixQrBase64,
    this.pixCode,
    this.checkoutUrl,
  });

  Color _statusColor(BuildContext context) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _statusLabel() {
    switch (status) {
      case 'approved':
        return 'Pagamento aprovado';
      case 'rejected':
        return 'Pagamento recusado';
      case 'cancelled':
        return 'Pagamento cancelado';
      case 'refunded':
        return 'Pagamento estornado';
      case 'chargeback':
        return 'Pagamento contestado';
      default:
        return 'Pagamento pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _statusLabel(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _statusColor(context),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(message!),
            ],
            if (pixQrBase64 != null && pixQrBase64!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(pixQrBase64!),
                  height: 160,
                  width: 160,
                  fit: BoxFit.contain,
                ),
              ),
            ],
            if (pixCode != null && pixCode!.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(pixCode!),
            ],
            if (checkoutUrl != null && checkoutUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText('Checkout: $checkoutUrl'),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Ja paguei, verificar status'),
            ),
          ],
        ),
      ),
    );
  }
}
