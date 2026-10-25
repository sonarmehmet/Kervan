import 'package:flutter_test/flutter_test.dart';
import 'package:kervan/features/event_creation/data/event_validators.dart';
import 'package:kervan/features/event_discovery/data/event_filter.dart';
import 'package:kervan/features/notifications/data/notification_item.dart';
import 'package:kervan/features/participation/data/join_request.dart';

void main() {
  group('EventValidators', () {
    test('başlık sınırları (3-80)', () {
      expect(EventValidators.title('ab'), isNotNull);
      expect(EventValidators.title('abc'), isNull);
      expect(EventValidators.title('a' * 80), isNull);
      expect(EventValidators.title('a' * 81), isNotNull);
    });

    test('kapasite sınırları (1-100)', () {
      expect(EventValidators.capacity('0'), isNotNull);
      expect(EventValidators.capacity('1'), isNull);
      expect(EventValidators.capacity('100'), isNull);
      expect(EventValidators.capacity('101'), isNotNull);
      expect(EventValidators.capacity('abc'), isNotNull);
      expect(EventValidators.capacity(''), isNotNull);
    });

    test('düzenlemede kapasite onaylı sayının altına inemez', () {
      expect(EventValidators.capacity('4', minCapacity: 5), isNotNull);
      expect(EventValidators.capacity('5', minCapacity: 5), isNull);
    });

    test('adres 3-200 karakter', () {
      expect(EventValidators.address(' '), isNotNull);
      expect(EventValidators.address('abc'), isNull);
      expect(EventValidators.address('a' * 201), isNotNull);
    });

    test('başlangıç zamanı gelecekte olmalı', () {
      final now = DateTime(2026, 10, 25, 12);
      expect(EventValidators.startsAt(null, now: now), isNotNull);
      expect(
        EventValidators.startsAt(now.subtract(const Duration(hours: 1)), now: now),
        isNotNull,
      );
      expect(
        EventValidators.startsAt(now.add(const Duration(hours: 1)), now: now),
        isNull,
      );
    });

    test('düzenlemede değişmeyen eski tarih kabul edilir', () {
      final now = DateTime(2026, 10, 25, 12);
      final old = now.subtract(const Duration(hours: 2));
      expect(
        EventValidators.startsAt(old, unchangedFrom: old, now: now),
        isNull,
      );
    });
  });

  group('EventFilter', () {
    test('boş filtre etkin değil', () {
      expect(const EventFilter().isActive, isFalse);
      expect(const EventFilter().activeCount, 0);
    });

    test('copyWith ve temizleme', () {
      final filter = const EventFilter().copyWith(city: 'İzmir', categoryId: 'yoga');
      expect(filter.activeCount, 2);
      final cleared = filter.copyWith(clearCity: true);
      expect(cleared.city, isNull);
      expect(cleared.categoryId, 'yoga');
    });

    test('eşitlik', () {
      expect(
        const EventFilter(city: 'Ankara'),
        const EventFilter(city: 'Ankara'),
      );
    });
  });

  group('Durum kimlikleri firestore şemasıyla uyumlu', () {
    test('RequestStatus', () {
      expect(
        RequestStatus.values.map((s) => s.id).toSet(),
        <String>{'pending', 'approved', 'rejected', 'cancelled'},
      );
      expect(RequestStatus.fromId('approved'), RequestStatus.approved);
    });

    test('NotificationType', () {
      expect(
        NotificationType.fromId('request_received'),
        NotificationType.requestReceived,
      );
      expect(NotificationType.fromId('bilinmeyen'), NotificationType.unknown);
    });
  });
}
