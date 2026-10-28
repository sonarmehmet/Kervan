import 'package:intl/intl.dart';

/// Türkçe tarih biçimleri. `main.dart` içinde `initializeDateFormatting('tr_TR')` çağrılmalıdır.
abstract final class DateFormatters {
  static const String _locale = 'tr_TR';

  /// Örnek: "24 Ekim 2026, 15:00"
  static String eventDateTime(DateTime date) =>
      DateFormat('d MMMM y, HH:mm', _locale).format(date.toLocal());

  /// Örnek: "24 Ekim 2026"
  static String shortDate(DateTime date) =>
      DateFormat('d MMMM y', _locale).format(date.toLocal());

  /// Örnek: "24 Ekim" veya aralıkta "24 - 26 Ekim" (ay farklıysa "30 Ekim - 2 Kasım").
  static String dateRange(DateTime start, [DateTime? end]) {
    final first = start.toLocal();
    if (end == null) return DateFormat('d MMMM', _locale).format(first);
    final last = end.toLocal();
    if (first.year == last.year && first.month == last.month && first.day == last.day) {
      return DateFormat('d MMMM', _locale).format(first);
    }
    if (first.month == last.month && first.year == last.year) {
      return '${first.day} - ${DateFormat('d MMMM', _locale).format(last)}';
    }
    return '${DateFormat('d MMMM', _locale).format(first)} - ${DateFormat('d MMMM', _locale).format(last)}';
  }

  /// Örnek: "15:00"
  static String timeOnly(DateTime date) =>
      DateFormat('HH:mm', _locale).format(date.toLocal());
}
