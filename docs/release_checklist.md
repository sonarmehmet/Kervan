# Kervan — Google Play Yayın Kontrol Listesi

Bu liste sırayla ilerlemen için hazırlandı. Kuralların bir kısmı zamanla değişir; ilgili satırlardaki
"doğrula" notlarını Play Console'daki güncel metinle karşılaştır.

## 1. Hesaplar

- [ ] Google Play Console geliştirici hesabı (tek seferlik ücret, kimlik doğrulaması ister).
- [ ] Kişisel hesap açtıysan yeni hesaplar için **kapalı test** şartı olabilir (belirli sayıda test kullanıcısı ve
      süre). Güncel sayı ve süreyi Play Console'da doğrula; bu süre yayın tarihini doğrudan etkiler, erken başla.
- [ ] Firebase projesi aynı Google hesabıyla yönetilsin; ikinci bir yönetici ekle (hesap kaybına karşı).

## 2. Uygulama kimliği ve imza

- [ ] Uygulama kimliği (`applicationId`) kesinleştir. Play'e çıktıktan sonra DEĞİŞTİRİLEMEZ. (`flutter create`
      komutundaki `--org` + proje adından oluşur, örn. `com.kervan.kervan`.)
- [ ] `android/app/build.gradle(.kts)` içinde `minSdk` en az 23 (Firebase şartı).
- [ ] Yükleme anahtarı (upload keystore) oluştur ve GÜVENLİ yerde yedekle:
      `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- [ ] `android/key.properties` dosyasını oluştur (`.gitignore` bunu zaten dışarıda tutar), `build.gradle` içinde
      release imzasını bu dosyaya bağla. Anahtar dosyası ve şifresi ASLA GitHub'a gitmemeli.
- [ ] Play Console'da **Play App Signing**'i etkinleştir (varsayılan).
- [ ] Sürüm: `pubspec.yaml` içindeki `version: 0.1.0+1` → her yüklemede `+N` (build numarası) artmalı.
- [ ] Paket oluştur: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`

## 3. Android izinleri

- [ ] `AndroidManifest.xml` içine bildirim izni (Android 13+):
      `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`
- [ ] İnternet izni release'de otomatik gelir; ek izin (konum, kamera vb.) EKLEME, gerekmiyor.
- [ ] Uygulama adı ve ikonu: `android/app/src/main/AndroidManifest.xml` (`android:label`) ve ikon dosyaları.
      (İkon paketi için `flutter_launcher_icons` kullanılabilir; 1024x1024 kaynak görsel hazırla.)

## 4. Firebase üretim ayarları

- [ ] `firebase deploy --only firestore` (kurallar ve indexler) ve `firebase deploy --only functions`.
- [ ] `rules_test` testlerini emulator ile çalıştır, hepsi geçmeden yayınlama.
- [ ] Google Cloud Console'da **bütçe uyarısı** (ör. aylık 5-10 dolar) ve gerekirse bütçe sınırı tanımla.
- [ ] Authentication: yalnızca kullandığın yöntemler açık. E-posta numaralandırma korumasını (enumeration
      protection) açmayı düşün.
- [ ] **App Check** (Play Integrity) etkinleştir: sahte istemcilerin Firestore'a erişmesini zorlaştırır.
- [ ] Firestore konumu `europe-west1` ve Functions bölgesi aynı olmalı (`functions/src/common.ts`).
- [ ] Şikâyetleri (`reports` koleksiyonu) düzenli kontrol edeceğin bir süreç belirle (aşağıda 7. bölüm).

## 5. Mağaza kaydı (Store listing)

- [ ] Uygulama adı (30 karakter), kısa açıklama (80), tam açıklama (4000) — Türkçe.
- [ ] Uygulama ikonu 512x512 PNG, öne çıkan görsel 1024x500, en az 2 telefon ekran görüntüsü.
- [ ] Kategori: Sosyal (veya Yaşam Tarzı).
- [ ] İletişim e-postası (herkese açık görünür).
- [ ] **Gizlilik politikası bağlantısı:** herkese açık, internetten erişilebilir bir adres. Taslak:
      `docs/privacy_policy_draft.md` (hukuki inceleme gerekir). GitHub Pages ile yayınlanabilir.

## 6. Play Console formları

- [ ] **Veri güvenliği (Data safety):** Toplanan veriler: e-posta, ad, şehir/ilçe ve kullanıcının yazdığı adres,
      kullanıcı içeriği (etkinlik, açıklama), cihaz kimliği/bildirim jetonu (FCM). Aktarım şifreli (HTTPS).
      Kullanıcı hesabını ve verilerini silebilir (uygulama içi). Üçüncü taraf: Google/Firebase.
- [ ] **Hesap silme:** Play, uygulama içi silmenin yanında **web üzerinden silme talebi bağlantısı** da ister
      (doğrula). Basit bir sayfa + e-posta adresi yeterli olabilir.
- [ ] **İçerik derecelendirmesi (IARC):** Kullanıcılar arası etkileşim ve kullanıcı üretimi içerik olduğunu işaretle.
- [ ] **Kullanıcı üretimi içerik (UGC) politikası:** Uygulamada olması gerekenler:
      şikâyet etme (var), kullanıcı engelleme (var), kötü içeriği kaldırma süreci (7. bölüm).
- [ ] Hedef kitle: 18 yaş ve üzeri öneririm (buluşma/sosyal uygulama). Çocuklara yönelik DEĞİL olarak işaretle.
- [ ] Reklam yok (ilk sürüm), uygulama içi satın alma yok.
- [ ] Hedef API düzeyi: Play'in güncel şartını karşılayan Flutter sürümüyle derle.

## 7. Moderasyon süreci (yayından önce netleştir)

- [ ] Şikâyetler Firebase Console → Firestore → `reports` koleksiyonunda görünür (`status: open`).
- [ ] Kuralı yaz: kaç saat içinde bakılır, hangi içerik kaldırılır, tekrar eden kullanıcı nasıl uzaklaştırılır.
- [ ] Gerekirse Firebase Console'dan kullanıcıyı devre dışı bırak (Authentication → kullanıcı → Disable).
- [ ] İleride: yönetici paneli veya Cloud Function ile otomatik uyarı.

## 8. Yayın adımları

1. Dahili test kanalı: kendin ve birkaç kişi (aab yükle, test kullanıcılarını e-postayla ekle).
2. Kapalı test: gereken sayıda kullanıcıyla gereken süre (gerekliyse).
3. Üretim (production) başvurusu: formlar tamam, Google incelemesi birkaç gün sürer.
4. Aşamalı yayın (ör. %20) ile başla, çökme raporlarını izle.

## 9. Sonraki sürümler için (bilerek ertelendi)

- Harita üzerinde konum seçme (Google Maps API anahtarı + faturalandırma gerekir).
- Bildirime dokununca etkinliği açma YAZILDI (derlenmedi, gerçek cihazda test edilmeli).
- Etkinlik sohbeti, gelişmiş arama/mesafe filtresi.
- Crashlytics ve Analytics (gizlilik politikası ve veri güvenliği formunu güncellemeyi unutma).
- iOS: Apple Developer hesabı (yıllık ücret) ve Mac/derleme servisi gerekir.
