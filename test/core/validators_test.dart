import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('boş ve hatalı adresi reddeder', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('  '), isNotNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('abc@d'), isNotNull);
    });

    test('geçerli adresi kabul eder', () {
      expect(Validators.email('ali@ornek.com'), isNull);
      expect(Validators.email(' ali@ornek.com '), isNull);
    });
  });

  group('Validators.password', () {
    test('8 karakterden kısa şifreyi reddeder', () {
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password(''), isNotNull);
    });

    test('8 karakter ve üstünü kabul eder', () {
      expect(Validators.password('12345678'), isNull);
    });
  });

  group('Validators.displayName', () {
    test('sınırları uygular (2-40)', () {
      expect(Validators.displayName('A'), isNotNull);
      expect(Validators.displayName('Ay'), isNull);
      expect(Validators.displayName('A' * 40), isNull);
      expect(Validators.displayName('A' * 41), isNotNull);
    });
  });

  group('Validators.bio', () {
    test('en fazla 280 karakter', () {
      expect(Validators.bio(''), isNull);
      expect(Validators.bio('a' * 280), isNull);
      expect(Validators.bio('a' * 281), isNotNull);
    });
  });
}
