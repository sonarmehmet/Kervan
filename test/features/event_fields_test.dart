import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/event_creation/data/event_validators.dart';
import 'package:rota/features/event_details/data/event.dart';

Event _event({int? duration, String? imageUrl}) => Event(
      id: 'e1',
      ownerId: 'o1',
      ownerName: 'Sahip',
      title: 'Yoga',
      description: '',
      category: 'yoga',
      city: 'Elazığ',
      district: '',
      startsAt: DateTime(2030, 1, 1, 17, 0),
      capacity: 5,
      acceptedCount: 0,
      status: EventStatus.active,
      durationMinutes: duration,
      imageUrl: imageUrl,
    );

void main() {
  group('durationLabel', () {
    test('dakika, saat ve buçuk', () {
      expect(durationLabel(30), '30 dk');
      expect(durationLabel(60), '1 saat');
      expect(durationLabel(90), '1,5 saat');
      expect(durationLabel(120), '2 saat');
      expect(durationLabel(135), '2 sa 15 dk');
    });

    test('seçilebilir süreler sınırlar içinde', () {
      for (final minutes in EventLimits.durations) {
        expect(minutes, inInclusiveRange(EventLimits.durationMin, EventLimits.durationMax));
      }
    });
  });

  group('Event ek alanları', () {
    test('süre yoksa endsAt null; varsa başlangıca eklenir', () {
      expect(_event().endsAt, isNull);
      expect(_event(duration: 120).endsAt, DateTime(2030, 1, 1, 19, 0));
    });

    test('hasImage boş veya null bağlantıda false', () {
      expect(_event().hasImage, isFalse);
      expect(_event(imageUrl: '').hasImage, isFalse);
      expect(_event(imageUrl: 'https://firebasestorage.googleapis.com/v0/b/x/o/a').hasImage, isTrue);
    });
  });

  group('maliyet notu ve koşullar doğrulayıcıları', () {
    test('boş geçerli, sınırı aşan geçersiz', () {
      expect(EventValidators.costNote(''), isNull);
      expect(EventValidators.costNote('a' * EventLimits.costNoteMax), isNull);
      expect(EventValidators.costNote('a' * (EventLimits.costNoteMax + 1)), isNotNull);
      expect(EventValidators.terms(null), isNull);
      expect(EventValidators.terms('a' * (EventLimits.termsMax + 1)), isNotNull);
    });
  });
}
