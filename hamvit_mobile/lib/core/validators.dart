import 'package:flutter/material.dart';

class Validators {
  static String normalizeDecimal(String input) => input.replaceAll(',', '.');

  static bool isInteger(String input) => int.tryParse(input) != null;
  static bool isDecimal(String input) => double.tryParse(normalizeDecimal(input)) != null;

  static bool isCpf(String cpf) {
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    return digits.length == 11;
  }

  static bool isCnpj(String cnpj) {
    final digits = cnpj.replaceAll(RegExp(r'\D'), '');
    return digits.length == 14;
  }

  static bool isPhoneBr(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 11;
  }

  static String toCouponUpper(String value) => value.trim().toUpperCase();

  static Future<DateTime?> pickDate(BuildContext context, {DateTime? initial}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 10),
    );
  }

  static Future<TimeOfDay?> pickTime(BuildContext context, {TimeOfDay? initial}) {
    return showTimePicker(context: context, initialTime: initial ?? TimeOfDay.now());
  }
}
