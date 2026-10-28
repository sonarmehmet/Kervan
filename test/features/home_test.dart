import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rota/core/constants/event_categories.dart';
import 'package:rota/core/theme/app_theme.dart';
import 'package:rota/core/widgets/date_badge.dart';
import 'package:rota/features/event_details/data/event.dart';
import 'package:rota/features/event_discovery/data/event_filter.dart';
import 'package:rota/features/event_discovery/data/event_query_repository.dart';
import 'package:rota/features/event_discovery/data/home_sections.dart';
import 'package:rota/features/event_discovery/data/time_preset.dart';
import 'package:rota/features/event_discovery/presentation/home_widgets.dart';

Event _event(
  String id, {
  int accepted = 0,
  int capacity = 10,
  int saves = 0,
  String owner = 'o',
  DateTime? createdAt,
  int startsInDays = 2,
  String category = 'yoga',
}) {
  return Event(
    id: id,
    ownerId: owner,
    ownerName: 'Sahip',
    title: id,
    description: '',
    category: category,
    city: 'İzmir',
    district: '',
    startsAt: DateTime(2030, 1, 1).add(Duration(days: startsInDays)),
    capacity: capacity,
    acceptedCount: accepted,
    status: EventStatus.active,
    saveCount: saves,
    createdAt: createdAt,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
  });

  group('TimePreset.range', () {
    // 28 Ekim 2026 Çarşamba, 25 Ekim Pazar, 24 Ekim Cumartesi
    test('çarşamba günü', () {
      final now = DateTime(2026, 10, 28, 15);
      expect(TimePreset.today.range(now), (start: DateTime(2026, 10, 28), end: DateTime(2026, 10, 28)));
      expect(TimePreset.tomorrow.range(now).start, DateTime(2026, 10, 29));
      expect(TimePreset.thisWeek.range(now), (start: DateTime(2026, 10, 28), end: DateTime(2026, 11, 1)));
      expect(TimePreset.thisWeekend.range(now), (start: DateTime(2026, 10, 31), end: DateTime(2026, 11, 1)));
      expect(TimePreset.nextWeek.range(now), (start: DateTime(2026, 11, 2), end: DateTime(2026, 11, 8)));
    });

    test('pazar günü: hafta sonu ve bu hafta yalnızca bugün', () {
      final now = DateTime(2026, 10, 25, 9);
      expect(TimePreset.thisWeek.range(now), (start: DateTime(2026, 10, 25), end: DateTime(2026, 10, 25)));
      expect(TimePreset.thisWeekend.range(now), (start: DateTime(2026, 10, 25), end: DateTime(2026, 10, 25)));
      expect(TimePreset.nextWeek.range(now).start, DateTime(2026, 10, 26));
    });

    test('cumartesi günü: hafta sonu cumartesi ve pazar', () {
      final now = DateTime(2026, 10, 24, 9);
      expect(TimePreset.thisWeekend.range(now), (start: DateTime(2026, 10, 24), end: DateTime(2026, 10, 25)));
    });
  });

  group('EventFilter aralık ve grup', () {
    test('withPreset aralığı uygular, aynısına tekrar basınca kaldırır', () {
      final now = DateTime(2026, 10, 28, 15);
      final filter = const EventFilter().withPreset(TimePreset.thisWeekend, now: now);
      expect(filter.date, DateTime(2026, 10, 31));
      expect(filter.dateEnd, DateTime(2026, 11, 1));
      expect(filter.preset, TimePreset.thisWeekend);
      expect(filter.until, DateTime(2026, 11, 2));
      expect(filter.withPreset(TimePreset.thisWeekend, now: now).date, isNull);
      expect(filter.withPreset(TimePreset.today, now: now).preset, TimePreset.today);
    });

    test('özel tarih tek gündür, hazır aralığı temizler', () {
      final base = const EventFilter().withPreset(TimePreset.thisWeek, now: DateTime(2026, 10, 28));
      final custom = base.copyWith(date: DateTime(2026, 12, 3));
      expect(custom.preset, isNull);
      expect(custom.dateEnd, isNull);
      expect(custom.until, DateTime(2026, 12, 4));
    });

    test('hasNarrowing ve activeCount', () {
      expect(const EventFilter(city: 'İzmir').hasNarrowing, isFalse);
      expect(const EventFilter(groupId: 'sports').hasNarrowing, isTrue);
      expect(const EventFilter(city: 'İzmir', groupId: 'sports').activeCount, 2);
      final cleared = const EventFilter(city: 'İzmir', groupId: 'sports', categoryId: 'yoga')
          .copyWith(clearGroup: true, clearCategory: true);
      expect(cleared.hasNarrowing, isFalse);
    });

    test('applyGroupFilter yalnızca o gruptaki etkinlikleri bırakır', () {
      final yoga = _event('yoga', category: 'yoga'); // spor ve hareket
      final other = _event('diger', category: 'photography');
      final groupId = EventCategory.byId('yoga').group.id;
      expect(applyGroupFilter([yoga, other], groupId).map((e) => e.id), ['yoga']);
      expect(applyGroupFilter([yoga, other], null), hasLength(2));
    });
  });

  group('HomeSections', () {
    test('öne çıkanlar puana göre, puansızlar dışarıda', () {
      final sections = HomeSections.build([
        _event('a', accepted: 1),
        _event('b', accepted: 3),
        _event('c', saves: 2), // puan 4
        _event('d'),
      ]);
      expect(sections.featured.map((e) => e.id), ['c', 'b', 'a']);
    });

    test('en çok kaydedilenler yalnızca kaydı olanlar', () {
      final sections = HomeSections.build([
        _event('a', saves: 1),
        _event('b', saves: 5),
        _event('c'),
      ]);
      expect(sections.mostSaved.map((e) => e.id), ['b', 'a']);
    });

    test('dolmak üzere: %70 ve üstü, dolu olmayan, en az 2 katılımcı', () {
      final sections = HomeSections.build([
        _event('yarisi', accepted: 5),
        _event('neredeyse', accepted: 8),
        _event('dolu', accepted: 10),
        _event('tek', accepted: 1, capacity: 1),
        _event('yuzde90', accepted: 9),
      ]);
      expect(sections.almostFull.map((e) => e.id), ['yuzde90', 'neredeyse']);
    });

    test('yeni eklenenler createdAt azalan, tarihsizler dışarıda', () {
      final sections = HomeSections.build([
        _event('eski', createdAt: DateTime(2026, 1, 1)),
        _event('yeni', createdAt: DateTime(2026, 6, 1)),
        _event('yok'),
      ]);
      expect(sections.newest.map((e) => e.id), ['yeni', 'eski']);
    });

    test('takip ettiklerim düzenleyene göre, şerit en fazla 10', () {
      final events = [
        for (var i = 0; i < 15; i++) _event('e$i', owner: i.isEven ? 'takip' : 'baska', accepted: 1),
      ];
      final sections = HomeSections.build(events, followedIds: {'takip'});
      expect(sections.following.every((e) => e.ownerId == 'takip'), isTrue);
      expect(sections.following.length, 8);
      expect(sections.featured.length, HomeSections.stripSize);
    });
  });

  group('DateBadge', () {
    testWidgets('gün, ay kısaltması ve saat', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: DateBadge(date: DateTime(2026, 11, 1, 17, 5))),
        ),
      );
      expect(find.text('1'), findsOneWidget);
      expect(find.text('KAS'), findsOneWidget);
      expect(find.text('17:05'), findsOneWidget);
    });

    test('ay kısaltmaları Türkçe büyük harf', () {
      expect(DateBadge.monthLabel(DateTime(2026, 10, 1)), 'EKİ');
      expect(DateBadge.monthLabel(DateTime(2026, 2, 1)), 'ŞUB');
      expect(DateBadge.monthLabel(DateTime(2026, 8, 1)), 'AĞU');
    });
  });

  group('Ana sayfa bileşenleri', () {
    testWidgets('TimeChips: hazır düğmeler ve özel tarih', (tester) async {
      TimePreset? tapped;
      var pickedDate = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TimeChips(
                filter: const EventFilter(),
                onPreset: (preset) => tapped = preset,
                onPickDate: () => pickedDate++,
              ),
            ),
          ),
        ),
      );
      for (final label in ['Bugün', 'Yarın', 'Bu Hafta', 'Bu Hafta Sonu', 'Gelecek Hafta', 'Farklı Bir Tarih']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('Bu Hafta Sonu'));
      expect(tapped, TimePreset.thisWeekend);
      await tester.tap(find.text('Farklı Bir Tarih'));
      expect(pickedDate, 1);
    });

    testWidgets('CategoryRow: kategori grubuna dokununca grup döner', (tester) async {
      EventCategoryGroup? picked;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: CategoryRow(onSelected: (group) => picked = group)),
        ),
      );
      await tester.tap(find.text(EventCategory.groups.first.label));
      expect(picked?.id, EventCategory.groups.first.id);
    });

    testWidgets('SectionHeader: Tümü yalnızca eylem varsa görünür', (tester) async {
      var seeAll = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Column(
              children: [
                SectionHeader(title: 'Öne çıkanlar', onSeeAll: () => seeAll++),
                const SectionHeader(title: 'Başlık'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Tümü'), findsOneWidget);
      await tester.tap(find.text('Tümü'));
      expect(seeAll, 1);
    });
  });
}
