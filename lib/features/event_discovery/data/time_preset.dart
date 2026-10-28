/// "Hangi zamanı planlıyorsun?" hazır tarih aralıkları.
enum TimePreset {
  today('Bugün'),
  tomorrow('Yarın'),
  thisWeek('Bu Hafta'),
  thisWeekend('Bu Hafta Sonu'),
  nextWeek('Gelecek Hafta');

  const TimePreset(this.label);

  final String label;

  /// Aralığın ilk ve son GÜNÜ (ikisi de dahil, saat kısmı 00:00).
  ({DateTime start, DateTime end}) range(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    // Pazartesi = 1 ... Pazar = 7
    final daysToSunday = DateTime.sunday - today.weekday;
    final sunday = today.add(Duration(days: daysToSunday));
    switch (this) {
      case TimePreset.today:
        return (start: today, end: today);
      case TimePreset.tomorrow:
        final tomorrow = today.add(const Duration(days: 1));
        return (start: tomorrow, end: tomorrow);
      case TimePreset.thisWeek:
        return (start: today, end: sunday);
      case TimePreset.thisWeekend:
        final saturday = sunday.subtract(const Duration(days: 1));
        return (start: saturday.isBefore(today) ? today : saturday, end: sunday);
      case TimePreset.nextWeek:
        final monday = sunday.add(const Duration(days: 1));
        return (start: monday, end: monday.add(const Duration(days: 6)));
    }
  }
}
