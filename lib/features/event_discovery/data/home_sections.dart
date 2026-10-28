import '../../event_details/data/event.dart';

/// Ana sayfadaki şeritler. Girdi: yaklaşan, aktif ve engellenmemiş etkinlikler (tarihe göre artan).
class HomeSections {
  const HomeSections({
    required this.following,
    required this.featured,
    required this.mostSaved,
    required this.almostFull,
    required this.newest,
  });

  /// Takip ettiğim düzenleyenlerin etkinlikleri.
  final List<Event> following;

  /// Öne çıkanlar: katılımcı ve kaydedilme sayısına göre.
  final List<Event> featured;

  /// En çok kaydedilenler ("en çok beğenilenler").
  final List<Event> mostSaved;

  /// Dolmak üzere olanlar (%70 ve üstü dolu, hâlâ yer var).
  final List<Event> almostFull;

  /// Yeni eklenenler.
  final List<Event> newest;

  static const int stripSize = 10;

  /// Öne çıkma puanı: onaylı katılımcı + 2 x kaydedilme.
  static int score(Event event) => event.acceptedCount + 2 * event.saveCount;

  static HomeSections build(
    List<Event> events, {
    Set<String> followedIds = const <String>{},
  }) {
    List<Event> top(Iterable<Event> items) =>
        items.take(stripSize).toList(growable: false);

    final featured = events.where((e) => score(e) > 0).toList()
      ..sort((a, b) {
        final byScore = score(b).compareTo(score(a));
        return byScore != 0 ? byScore : a.startsAt.compareTo(b.startsAt);
      });

    final mostSaved = events.where((e) => e.saveCount > 0).toList()
      ..sort((a, b) {
        final bySaves = b.saveCount.compareTo(a.saveCount);
        return bySaves != 0 ? bySaves : a.startsAt.compareTo(b.startsAt);
      });

    double fill(Event e) => e.capacity == 0 ? 0 : e.acceptedCount / e.capacity;
    final almostFull = events
        .where((e) => !e.isFull && e.acceptedCount >= 2 && fill(e) >= 0.7)
        .toList()
      ..sort((a, b) => fill(b).compareTo(fill(a)));

    final newest = events.where((e) => e.createdAt != null).toList()
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    final following =
        events.where((e) => followedIds.contains(e.ownerId)).toList();

    return HomeSections(
      following: top(following),
      featured: top(featured),
      mostSaved: top(mostSaved),
      almostFull: top(almostFull),
      newest: top(newest),
    );
  }
}
