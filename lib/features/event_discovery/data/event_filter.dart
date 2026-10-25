/// Keşif ekranı filtreleri. Boş alan = o alana göre süzme yok.
class EventFilter {
  const EventFilter({this.city, this.categoryId, this.date});

  final String? city;
  final String? categoryId;

  /// Seçilen günün tamamı (saat kısmı yok sayılır).
  final DateTime? date;

  bool get isActive => activeCount > 0;

  int get activeCount =>
      (city != null ? 1 : 0) +
      (categoryId != null ? 1 : 0) +
      (date != null ? 1 : 0);

  /// Boş bırakılan alan korunur; temizlemek için ilgili `clear*` bayrağını kullan.
  EventFilter copyWith({
    String? city,
    String? categoryId,
    DateTime? date,
    bool clearCity = false,
    bool clearCategory = false,
    bool clearDate = false,
  }) {
    return EventFilter(
      city: clearCity ? null : (city ?? this.city),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      date: clearDate ? null : (date ?? this.date),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EventFilter &&
      other.city == city &&
      other.categoryId == categoryId &&
      other.date == date;

  @override
  int get hashCode => Object.hash(city, categoryId, date);
}
