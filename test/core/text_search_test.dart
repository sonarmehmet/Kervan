import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/utils/text_search.dart';

void main() {
  group('foldTr', () {
    test('Türkçe harfleri sadeleştirir', () {
      expect(foldTr('İstanbul'), 'istanbul');
      expect(foldTr('ISPARTA'), 'isparta');
      expect(foldTr('Çay Şöleni ÜĞ'), 'cay soleni ug');
      expect(foldTr('ığdır'), 'igdir');
    });
  });

  group('matchesSearch', () {
    test('boş sorgu her şeyle eşleşir', () {
      expect(matchesSearch('', ['x']), isTrue);
      expect(matchesSearch('   ', ['x']), isTrue);
    });

    test('harf biçimi ve aksan farkını yok sayar', () {
      expect(matchesSearch('istanbul', ['İstanbul', 'Kadıköy']), isTrue);
      expect(matchesSearch('kadikoy', ['İstanbul', 'Kadıköy']), isTrue);
      expect(matchesSearch('FUTBOL', ['Halı saha futbol']), isTrue);
    });

    test('tüm sözcükler (farklı alanlarda bile) bulunmalı', () {
      final fields = ['Sabah koşusu', 'Spor ve hareket', 'Elazığ'];
      expect(matchesSearch('sabah elazig', fields), isTrue);
      expect(matchesSearch('sabah izmir', fields), isFalse);
    });
  });
}
