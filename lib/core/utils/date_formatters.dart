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

  /// Örnek: "15:00"
  static String timeOnly(DateTime date) =>
      DateFormat('HH:mm', _locale).format(date.toLocal());
}
