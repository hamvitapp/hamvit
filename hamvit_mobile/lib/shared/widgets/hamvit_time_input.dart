import 'package:flutter/services.dart';

class HamvitTimeMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    final hourPart = limited.length >= 2 ? limited.substring(0, 2) : limited;
    final minutePart = limited.length > 2 ? limited.substring(2) : '';

    var hour = int.tryParse(hourPart) ?? 0;
    if (hour > 23) hour = 23;
    final normalizedHour = hourPart.length == 2 ? hour.toString().padLeft(2, '0') : hourPart;

    var normalizedMinute = minutePart;
    if (minutePart.length == 2) {
      var minute = int.tryParse(minutePart) ?? 0;
      if (minute > 59) minute = 59;
      normalizedMinute = minute.toString().padLeft(2, '0');
    }

    final formatted = normalizedMinute.isEmpty ? normalizedHour : '$normalizedHour:$normalizedMinute';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
