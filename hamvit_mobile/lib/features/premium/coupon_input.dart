import 'package:flutter/material.dart';

class CouponInput extends StatelessWidget {
  final TextEditingController controller;
  const CouponInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: 'Cupom de nutricionista (opcional)',
        hintText: 'Ex: NUTRI10',
        prefixIcon: const Icon(Icons.local_offer_outlined),
        suffixIcon: IconButton(
          onPressed: controller.clear,
          icon: const Icon(Icons.close),
          tooltip: 'Limpar cupom',
        ),
      ),
    );
  }
}
