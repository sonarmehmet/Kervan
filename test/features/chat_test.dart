import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/constants/firestore_paths.dart';
import 'package:rota/features/chat/data/chat_message.dart';

void main() {
  group('ChatLimits.validate', () {
    test('boş ve yalnızca boşluk reddedilir', () {
      expect(ChatLimits.validate(null), isNotNull);
      expect(ChatLimits.validate(''), isNotNull);
      expect(ChatLimits.validate('   '), isNotNull);
    });

    test('1-500 karakter kabul edilir, 501 reddedilir', () {
      expect(ChatLimits.validate('a'), isNull);
      expect(ChatLimits.validate('a' * 500), isNull);
      expect(ChatLimits.validate('a' * 501), isNotNull);
    });
  });

  test('sohbet yolu etkinlik altındadır', () {
    expect(FirestorePaths.eventMessages('e1'), 'events/e1/messages');
  });
}
