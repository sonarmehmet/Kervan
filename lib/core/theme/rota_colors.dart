import 'package:flutter/material.dart';

/// Rota renk paleti. Sıcak kırık beyaz zemin, koyu mürekkep düğmeler, canlı vurgular.
abstract final class RotaColors {
  // Vurgular (açık ve koyu temada aynı)
  static const Color sun = Color(0xFFF5C945); // sarı: rozetler, vurgu
  static const Color ember = Color(0xFFEE7030); // turuncu: ikincil vurgu
  static const Color plum = Color(0xFF3F0F6B); // mor: kategori rozetleri
  static const Color sky = Color(0xFF8FA8FF); // açık mavi: illüstrasyon

  // Açık tema
  static const Color paper = Color(0xFFF1F0EA); // sayfa zemini
  static const Color card = Color(0xFFF8F7F2); // kart zemini
  static const Color field = Color(0xFFE6E5DF); // form alanı dolgusu
  static const Color ink = Color(0xFF232323); // metin ve düğme
  static const Color inkSoft = Color(0xFF6B6A66); // ikincil metin
  static const Color line = Color(0xFFDAD8D0); // kenarlık

  // Koyu tema
  static const Color nightPaper = Color(0xFF161513);
  static const Color nightCard = Color(0xFF211F1C);
  static const Color nightField = Color(0xFF2C2A26);
  static const Color nightInk = Color(0xFFF1F0EA);
  static const Color nightInkSoft = Color(0xFFA8A69F);
  static const Color nightLine = Color(0xFF3A3834);

  /// Kategori grupları için dönüşümlü vurgu renkleri (sıra sabit).
  static const List<Color> accents = <Color>[sun, ember, plum, sky];

  static Color accentAt(int index) => accents[index % accents.length];

  /// Verilen zemin üzerinde okunur metin rengi.
  static Color onAccent(Color background) =>
      background.computeLuminance() > 0.45 ? ink : paper;
}
