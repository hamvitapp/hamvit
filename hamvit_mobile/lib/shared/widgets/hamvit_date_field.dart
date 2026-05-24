import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/hamvit_date_utils.dart';

class _DateInputMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      if ((i == 1 || i == 3) && i != limited.length - 1) {
        buffer.write('/');
      }
    }

    final masked = buffer.toString();
    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }
}

class HamvitDateField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<String?> onIsoChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  const HamvitDateField({
    super.key,
    required this.label,
    required this.controller,
    required this.onIsoChanged,
    this.hint = 'DD/MM/AAAA',
    this.firstDate,
    this.lastDate,
    this.validator,
    this.enabled = true,
  });

  @override
  State<HamvitDateField> createState() => _HamvitDateFieldState();
}

class _HamvitDateFieldState extends State<HamvitDateField> {
  final _mask = _DateInputMaskFormatter();

  DateTime _safeInitialDate({
    required DateTime? current,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    final base = current ?? DateTime.now();
    if (base.isBefore(firstDate)) return firstDate;
    if (base.isAfter(lastDate)) return lastDate;
    return base;
  }

  Future<void> _pickDate() async {
    if (!widget.enabled) return;

    final now = DateTime.now();
    final firstDate = widget.firstDate ?? DateTime(1900);
    final lastDate = widget.lastDate ?? DateTime(now.year + 10);
    final current = HamvitDateUtils.tryParseBrDate(widget.controller.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: _safeInitialDate(
        current: current,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione uma data',
    );

    if (picked == null) return;
    widget.controller.text = HamvitDateUtils.formatDateBr(picked);
    widget.onIsoChanged(HamvitDateUtils.toIsoDate(picked));
    setState(() {});
  }

  String? _validate(String? value) {
    final parsed = HamvitDateUtils.tryParseBrDate(value ?? '');
    if ((value ?? '').trim().isNotEmpty && parsed == null) {
      return 'Data inválida. Use DD/MM/AAAA.';
    }
    return widget.validator?.call(value);
  }

  void _onChanged(String value) {
    final parsed = HamvitDateUtils.tryParseBrDate(value);
    if (parsed == null) {
      widget.onIsoChanged(null);
      return;
    }
    widget.onIsoChanged(HamvitDateUtils.toIsoDate(parsed));
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')), _mask],
      validator: _validate,
      onChanged: _onChanged,
      onTap: widget.enabled ? _pickDate : null,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        suffixIcon: IconButton(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_month_outlined),
          tooltip: 'Abrir calendário',
        ),
      ),
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
    );
  }
}
