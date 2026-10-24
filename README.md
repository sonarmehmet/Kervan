# Kervan

Birlikte aktivite yapmak isteyen insanları buluşturan sosyal etkinlik uygulaması.
Birisi etkinlik oluşturur, diğerleri katılım talebi gönderir, etkinlik sahibi onaylar veya reddeder.

- Mobil: Flutter, Dart, Material 3, Riverpod, GoRouter
- Sunucu: Firebase Authentication, Cloud Firestore, Cloud Functions
- Hedef: önce Android (Google Play), mimari iOS'a uygun

## Dokümantasyon

- `docs/firestore_schema.md`: veri şeması ve Cloud Functions sözleşmesi
- `docs/parallel_work.md`: üç geliştirici (A, B, C) için iş bölümü ve talimatlar

## Durum

Aşama 2 başladı: yapılandırma dosyaları, güvenlik kuralları ve indexler yazıldı.
Dart kodu henüz yazılmadı. Flutter bu geliştirme ortamında kurulamadığı için derleme ve test
yapılamadı; `flutter analyze` ve `flutter test` yerel makinede çalıştırılmalı.

## İlk kurulum (kendi bilgisayarında)

1. Flutter SDK ve Firebase CLI kur.
2. `flutter create . --project-name kervan --org com.example --platforms android,ios`
   (mevcut dosyaların üzerine yazmaz; `pubspec.yaml` farklı çıkarsa mevcut olanı koru)
3. Firebase projeni oluştur, `flutterfire configure` çalıştır (`lib/firebase_options.dart` üretilir, commit edilmez).
4. `flutter pub get`
