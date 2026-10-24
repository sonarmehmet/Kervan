import 'package:flutter_test/flutter_test.dart';
import 'package:kervan/core/constants/event_categories.dart';
import 'package:kervan/core/constants/firestore_paths.dart';
import 'package:kervan/core/constants/turkey_cities.dart';

void main() {
  group('TurkeyCities', () {
    test('81 benzersiz il içerir', () {
      expect(TurkeyCities.all.length, 81);
      expect(TurkeyCities.all.toSet().length, 81);
    });

    test('il adları firestore.rules sınırlarına uyar (2-30 karakter)', () {
      for (final city in TurkeyCities.all) {
        expect(city.length, inInclusiveRange(2, 30), reason: city);
      }
    });
  });

  group('EventCategory', () {
    test('kimlikler benzersiz', () {
      final ids = EventCategory.all.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('byId bilinmeyen kimlikte other döner', () {
      expect(EventCategory.byId('yok-boyle-bir-sey'), EventCategory.other);
      expect(EventCategory.byId('yoga'), EventCategory.yoga);
    });

    test('isValidId', () {
      expect(EventCategory.isValidId('sport'), isTrue);
      expect(EventCategory.isValidId('xyz'), isFalse);
    });
  });

  group('FirestorePaths', () {
    test('yollar şemayla uyumlu', () {
      expect(FirestorePaths.user('u1'), 'users/u1');
      expect(FirestorePaths.userBlock('u1', 'u2'), 'users/u1/blocks/u2');
      expect(FirestorePaths.eventLocation('e1'), 'events/e1/private/location');
      expect(FirestorePaths.eventRequest('e1', 'u1'), 'events/e1/requests/u1');
      expect(
        FirestorePaths.eventParticipant('e1', 'u1'),
        'events/e1/participants/u1',
      );
      expect(
        FirestorePaths.userNotifications('u1'),
        'notifications/u1/items',
      );
    });
  });
}
