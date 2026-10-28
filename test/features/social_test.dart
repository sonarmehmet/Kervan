import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rota/core/theme/app_theme.dart';
import 'package:rota/features/chat/data/chat_message.dart';
import 'package:rota/features/event_creation/data/recurrence.dart';
import 'package:rota/features/event_details/data/event.dart';
import 'package:rota/features/event_details/data/event_share.dart';
import 'package:rota/features/groups/data/group.dart';
import 'package:rota/features/notifications/data/notification_item.dart';
import 'package:rota/features/ratings/data/user_stats.dart';
import 'package:rota/features/ratings/presentation/event_rating_section.dart';
import 'package:rota/features/ratings/presentation/rating_widgets.dart';

Event _event({
  DateTime? startsAt,
  EventStatus status = EventStatus.active,
  String description = '',
}) {
  return Event(
    id: 'ev1',
    ownerId: 'o',
    ownerName: 'Sahip',
    title: 'Sabah koşusu',
    description: description,
    category: 'running',
    city: 'Elazığ',
    district: 'Merkez',
    startsAt: startsAt ?? DateTime.utc(2026, 11, 7, 6, 30),
    capacity: 5,
    acceptedCount: 1,
    status: status,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
  });

  group('occurrenceDates', () {
    final start = DateTime(2026, 1, 31, 18, 30);

    test('tekrar yoksa yalnızca başlangıç', () {
      expect(occurrenceDates(start, Recurrence.none, 5), [start]);
    });

    test('haftalık ve 2 haftada bir; saat korunur', () {
      final weekly = occurrenceDates(start, Recurrence.weekly, 3);
      expect(weekly, [
        DateTime(2026, 1, 31, 18, 30),
        DateTime(2026, 2, 7, 18, 30),
        DateTime(2026, 2, 14, 18, 30),
      ]);
      final biweekly = occurrenceDates(start, Recurrence.biweekly, 2);
      expect(biweekly.last, DateTime(2026, 2, 14, 18, 30));
    });

    test('aylık: ayın son gününü aşan gün ayın sonuna çekilir', () {
      final monthly = occurrenceDates(start, Recurrence.monthly, 4);
      expect(monthly, [
        DateTime(2026, 1, 31, 18, 30),
        DateTime(2026, 2, 28, 18, 30),
        DateTime(2026, 3, 31, 18, 30),
        DateTime(2026, 4, 30, 18, 30),
      ]);
    });

    test('yıl sonunu aşar ve sayı 2-12 ile sınırlanır', () {
      final dates = occurrenceDates(DateTime(2026, 11, 15, 10), Recurrence.monthly, 99);
      expect(dates.length, RecurrenceLimits.maxOccurrences);
      expect(dates[2], DateTime(2027, 1, 15, 10));
      expect(occurrenceDates(start, Recurrence.weekly, 1).length, 1);
    });
  });

  group('UserStats', () {
    test('ortalama en az 3 puanda görünür (anonimlik)', () {
      expect(const UserStats(organizerSum: 10, organizerCount: 2).organizerAverage, isNull);
      expect(const UserStats(organizerSum: 13, organizerCount: 3).organizerAverage, closeTo(4.33, 0.01));
      expect(UserStats.empty.participantAverage, isNull);
    });

    test('formatRating Türkçe ondalık', () {
      expect(formatRating(4.55), anyOf('4,5', '4,6'));
      expect(formatRating(5), '5,0');
    });
  });

  group('RatingText', () {
    testWidgets('yeterli puan yoksa "Yeni" gösterir', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: RatingText(average: null, count: 1)),
      ));
      expect(find.textContaining('Yeni'), findsOneWidget);
    });

    testWidgets('ortalama ve sayı gösterir', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: RatingText(average: 4.6, count: 12)),
      ));
      expect(find.text('4,6 (12)'), findsOneWidget);
    });
  });

  group('StarPicker', () {
    testWidgets('dokunulan yıldız değeri döner', (tester) async {
      var value = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: StarPicker(value: value, onChanged: (v) => value = v)),
      ));
      await tester.tap(find.byTooltip('4 yıldız'));
      expect(value, 4);
    });
  });

  group('EventRatingSection.isOpen', () {
    final now = DateTime(2026, 11, 10, 12);

    test('başlamadan önce kapalı, başladıktan sonra 30 gün açık', () {
      expect(EventRatingSection.isOpen(_event(startsAt: now.add(const Duration(hours: 1))), now), isFalse);
      expect(EventRatingSection.isOpen(_event(startsAt: now.subtract(const Duration(hours: 1))), now), isTrue);
      expect(EventRatingSection.isOpen(_event(startsAt: now.subtract(const Duration(days: 31))), now), isFalse);
    });

    test('iptal edilen etkinlikte kapalı', () {
      expect(
        EventRatingSection.isOpen(
          _event(startsAt: now.subtract(const Duration(hours: 1)), status: EventStatus.cancelled),
          now,
        ),
        isFalse,
      );
    });
  });

  group('paylaşım ve takvim', () {
    test('paylaşım metni tam adres içermez, bağlantı yalnızca taban adres varsa eklenir', () {
      final withoutLink = buildShareText(_event(), baseUrl: '');
      expect(withoutLink, contains('Sabah koşusu'));
      expect(withoutLink, contains('Merkez, Elazığ'));
      expect(withoutLink, isNot(contains('http')));
      final withLink = buildShareText(_event(), baseUrl: 'https://rota.web.app/');
      expect(withLink, contains('https://rota.web.app/events/ev1'));
    });

    test('takvim bağlantısı UTC tarih aralığı ve başlık içerir', () {
      final uri = calendarUri(_event(description: 'Birlikte koşalım'), baseUrl: '');
      expect(uri.host, 'calendar.google.com');
      expect(uri.queryParameters['action'], 'TEMPLATE');
      expect(uri.queryParameters['text'], 'Sabah koşusu');
      expect(uri.queryParameters['dates'], '20261107T063000Z/20261107T083000Z');
      expect(uri.queryParameters['location'], 'Merkez, Elazığ');
      expect(uri.queryParameters['details'], contains('Birlikte koşalım'));
    });
  });

  group('bildirim metinleri', () {
    NotificationItem item(NotificationType type, {String actor = '', String group = ''}) =>
        NotificationItem(
          id: '1',
          type: type,
          eventId: 'e',
          eventTitle: 'Koşu',
          read: false,
          actorName: actor,
          groupName: group,
        );

    test('yeni türler Türkçe mesaj üretir', () {
      expect(NotificationType.fromId('waitlist_spot_open'), NotificationType.waitlistSpotOpen);
      expect(NotificationType.fromId('event_reminder_24h'), NotificationType.eventReminder24h);
      expect(item(NotificationType.waitlistSpotOpen).message, contains('yer açıldı'));
      expect(item(NotificationType.eventReminder1h).message, contains('1 saat'));
      expect(item(NotificationType.newFollowedEvent, actor: 'Ayşe').message, contains('Ayşe'));
      expect(item(NotificationType.newGroupEvent, group: 'Koşu Grubu').message, contains('Koşu Grubu'));
    });
  });

  group('GroupLimits', () {
    test('ad 3-50, açıklama en fazla 500', () {
      expect(GroupLimits.name('ab'), isNotNull);
      expect(GroupLimits.name('abc'), isNull);
      expect(GroupLimits.name('a' * 51), isNotNull);
      expect(GroupLimits.description('a' * 501), isNotNull);
      expect(GroupLimits.description(''), isNull);
    });
  });

  test('ChatLimits hâlâ geçerli', () {
    expect(ChatLimits.validate('merhaba'), isNull);
  });
}
