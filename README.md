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

- A bölümü, 1. adım (core + giriş + profil) yazıldı: tema, router, ortak widget'lar, sabitler,
  e-posta/şifre ile kayıt-giriş-şifre sıfırlama, profil oluşturma/düzenleme.
- Henüz yazılmadı: ayarlar, hesap silme, engelleme/şikâyet (A, sonraki adım), etkinlikler (B), katılım ve sunucu (C).
- Router'da B ve C ekranları şimdilik `PlaceholderScreen` ile duruyor.
- DERLENMEDİ: kod yazılırken Flutter erişilebilir değildi. İlk işin `flutter pub get`, `flutter analyze`
  ve `flutter test` çalıştırıp çıkan hataları bildirmek olmalı.

## İlk kurulum (kendi bilgisayarında)

1. Flutter SDK ve Firebase CLI kur.
2. `flutter create . --project-name kervan --org com.example --platforms android,ios`
   (mevcut dosyaların üzerine yazmaz; `pubspec.yaml` farklı çıkarsa mevcut olanı koru)
3. Firebase projeni oluştur, `flutterfire configure` çalıştır (`lib/firebase_options.dart` üretilir, commit edilmez).
4. `flutter pub get`
