/// Tekrarlayan etkinlik kuralı. Seri, bağımsız etkinlikler olarak oluşturulur
/// (ortak `seriesId`, sıra `seriesIndex`); her biri ayrı ayrı iptal edilebilir.
enum Recurrence {
  none('none', 'Tekrarlama'),
  weekly('weekly', 'Her hafta'),
  biweekly('biweekly', '2 haftada bir'),
  monthly('monthly', 'Her ay');

  const Recurrence(this.id, this.label);
  final String id;
  final String label;
}

abstract final class RecurrenceLimits {
  static const int minOccurrences = 2;
  static const int maxOccurrences = 12; // firestore.rules: seriesIndex < 12
}

/// Serinin başlangıç tarihlerini üretir (ilk eleman [start]).
/// Saat (duvar saati) korunur; aylık tekrarda ayın son gününü aşan gün ayın son gününe çekilir
/// (örn. 31 Ocak -> 28/29 Şubat).
List<DateTime> occurrenceDates(DateTime start, Recurrence rule, int count) {
  if (rule == Recurrence.none || count <= 1) return <DateTime>[start];
  final total = count.clamp(RecurrenceLimits.minOccurrences, RecurrenceLimits.maxOccurrences);
  final dates = <DateTime>[];
  for (var i = 0; i < total; i++) {
    switch (rule) {
      case Recurrence.weekly:
        dates.add(DateTime(start.year, start.month, start.day + 7 * i, start.hour, start.minute));
      case Recurrence.biweekly:
        dates.add(DateTime(start.year, start.month, start.day + 14 * i, start.hour, start.minute));
      case Recurrence.monthly:
        final monthIndex = start.month - 1 + i;
        final year = start.year + monthIndex ~/ 12;
        final month = monthIndex % 12 + 1;
        final lastDay = DateTime(year, month + 1, 0).day;
        final day = start.day > lastDay ? lastDay : start.day;
        dates.add(DateTime(year, month, day, start.hour, start.minute));
      case Recurrence.none:
        break;
    }
  }
  return dates;
}
