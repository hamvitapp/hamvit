import 'package:intl/intl.dart';

class HamvitDateUtils {
  static final DateFormat _brFormatter = DateFormat('dd/MM/yyyy', 'pt_BR');

  static String formatDateBr(DateTime date) => _brFormatter.format(date);

  static String? formatIsoToBr(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    final parsed = tryParseIsoDate(iso);
    if (parsed == null) return null;
    return formatDateBr(parsed);
  }

  static DateTime? tryParseIsoDate(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;
    try {
      return DateTime.parse(cleaned);
    } catch (_) {
      return null;
    }
  }

  static String toIsoDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().substring(0, 10);
  }

  static DateTime? tryParseBrDate(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;

    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(cleaned);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }

    return parsed;
  }
}
