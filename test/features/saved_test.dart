import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/event_details/data/event.dart';
import 'package:rota/features/saved/data/saved_repository.dart';

Event _at(String id, DateTime startsAt) => Event(
      id: id,
      ownerId: 'o',
      ownerName: 'Sahip',
      title: id,
      description: '',
      category: 'yoga',
      city: 'Elazığ',
      district: '',
      startsAt: startsAt,
      capacity: 5,
      acceptedCount: 0,
      status: EventStatus.active,
    );

void main() {
  test('sortSavedEvents: yaklaşanlar tarihe göre artan, geçmişler sonda en yeni önce', () {
    final now = DateTime(2030, 6, 1, 12);
    final sorted = sortSavedEvents(<Event>[
      _at('gecmis-eski', DateTime(2030, 5, 1)),
      _at('yakin', DateTime(2030, 6, 2)),
      _at('gecmis-yeni', DateTime(2030, 5, 30)),
      _at('uzak', DateTime(2030, 7, 1)),
    ], now);
    expect(sorted.map((e) => e.id).toList(), ['yakin', 'uzak', 'gecmis-yeni', 'gecmis-eski']);
  });

  test('sortSavedEvents boş listede boş döner', () {
    expect(sortSavedEvents(const <Event>[], DateTime.now()), isEmpty);
  });

  test('Event.saveCount varsayılan 0', () {
    expect(_at('a', DateTime(2030)).saveCount, 0);
  });
}
