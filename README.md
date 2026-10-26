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

Tüm ilk sürüm özellikleri yazıldı (derlenmemiş Flutter kodu hariç aşağıdaki notlara bak):

- Hesap: kayıt, giriş, şifre sıfırlama, profil, ayarlar, hesap silme, engelleme, şikâyet
- Etkinlik: oluşturma, düzenleme, iptal, keşif (şehir/kategori/tarih filtreleri), detay, Etkinliklerim
- Katılım: talep gönder/geri çek, sahip onay/red, katılımcı listesi, ayrılma
- Bildirimler: uygulama içi liste, okundu işareti, rozet, push bildirimi (FCM)
- Etkinlik adresini harita uygulamasında açma (API anahtarı gerekmez)
- Sunucu: Cloud Functions (TypeScript) ve Firestore güvenlik kuralları

Doğrulama durumu (dürüst özet):

| Parça | Durum |
|---|---|
| Flutter A bölümü (core, giriş, profil, ayarlar, moderasyon) | `flutter analyze` temiz, 14 test geçti (kullanıcı makinesinde) |
| Flutter etkinlik/katılım/bildirim ekranları | Yazıldı, henüz DERLENMEDİ |
| Cloud Functions | `tsc` ile derlendi, 6 fonksiyon yükleniyor; emulator ile çalıştırılmadı |
| `firestore.rules` testleri (`rules_test/`) | Yazıldı, henüz ÇALIŞTIRILMADI (emulator bu ortamda indirilemedi) |

Henüz yok: harita üzerinde konum seçme, Android yayın imzası,
gerçek gizlilik politikası metni (uygulamadaki metin yer tutucudur; taslak: `docs/privacy_policy_draft.md`),
uygulama ikonu. Yayın adımları: `docs/release_checklist.md`.

Push bildirimi için Android'de `AndroidManifest.xml` içine şu satırı ekle (Android 13+):
`<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`

## İlk kurulum (kendi bilgisayarında)

1. Flutter SDK ve Firebase CLI kur.
2. `flutter create . --project-name kervan --org com.example --platforms android,ios`
   (mevcut dosyaların üzerine yazmaz; `pubspec.yaml` farklı çıkarsa mevcut olanı koru)
3. Firebase projeni oluştur, `flutterfire configure` çalıştır (`lib/firebase_options.dart` üretilir, commit edilmez).
4. `flutter pub get`
