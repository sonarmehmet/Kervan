import 'time_preset.dart';

/// Keşif ekranı filtreleri. Boş alan = o alana göre süzme yok.
class EventFilter {
  const EventFilter({
    this.city,
    this.categoryId,
    this.groupId,
    this.date,
    this.dateEnd,
    this.preset,
  });

  final String? city;

  /// Tek bir kategori (`EventCategory.id`).
  final String? categoryId;

  /// Bir kategori grubunun tamamı (`EventCategoryGroup.id`); ana sayfadaki yuvarlak kategoriler.
  final String? groupId;

  /// Seçilen aralığın ilk günü (saat kısmı yok sayılır).
  final DateTime? date;

  /// Aralığın son günü (dahil). `null` ise yalnızca [date] günü.
  final DateTime? dateEnd;

  /// Hazır aralık seçildiyse hangisi (vurgu için); özel tarihte `null`.
  final TimePreset? preset;

  bool get isActive => activeCount > 0;

  /// Şehir tercih sayılır, kategori/grup/tarih süzgeçtir; hepsi sayıma girer.
  int get activeCount =>
      (city != null ? 1 : 0) +
      (categoryId != null ? 1 : 0) +
      (groupId != null ? 1 : 0) +
      (date != null ? 1 : 0);

  /// Şehir dışında kategori, grup veya tarih seçili mi? (sonuç listesi modu)
  bool get hasNarrowing => categoryId != null || groupId != null || date != null;

  /// Boş bırakılan alan korunur; temizlemek için ilgili `clear*` bayrağını kullan.
  EventFilter copyWith({
    String? city,
    String? categoryId,
    String? groupId,
    DateTime? date,
    DateTime? dateEnd,
    TimePreset? preset,
    bool clearCity = false,
    bool clearCategory = false,
    bool clearGroup = false,
    bool clearDate = false,
  }) {
    return EventFilter(
      city: clearCity ? null : (city ?? this.city),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      date: clearDate ? null : (date ?? this.date),
      dateEnd: clearDate ? null : (date != null ? dateEnd : (dateEnd ?? this.dateEnd)),
      preset: clearDate ? null : (date != null ? preset : (preset ?? this.preset)),
    );
  }

  /// Hazır aralığı uygular (ya da aynı aralık seçiliyse kaldırır).
  EventFilter withPreset(TimePreset? value, {DateTime? now}) {
    if (value == null || value == preset) return copyWith(clearDate: true);
    final range = value.range(now ?? DateTime.now());
    return copyWith(date: range.start, dateEnd: range.end, preset: value);
  }

  /// Sorgunun üst sınırı (dışlayıcı): son günün ertesi 00:00.
  DateTime? get until {
    final first = date;
    if (first == null) return null;
    final last = dateEnd ?? first;
    final day = DateTime(last.year, last.month, last.day);
    return day.add(const Duration(days: 1));
  }

  @override
  bool operator ==(Object other) =>
      other is EventFilter &&
      other.city == city &&
      other.categoryId == categoryId &&
      other.groupId == groupId &&
      other.date == date &&
      other.dateEnd == dateEnd &&
      other.preset == preset;

  @override
  int get hashCode => Object.hash(city, categoryId, groupId, date, dateEnd, preset);
}
