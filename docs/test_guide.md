# Rota — Kurulum ve Test Rehberi

## A. Kurulum (bir kez)

1. **Dalı al:** `git fetch && git checkout feat/push-docs && git pull`
2. **Android klasörü:** `bash scripts/setup_android.sh com.SENIN.rota`
   (Windows'ta Git Bash veya WSL; `com.SENIN` kısmı senin alan adın, Play'e çıkınca DEĞİŞMEZ.)
   Bu betik `android/` klasörünü oluşturur, minSdk 23 yapar, bildirim iznini ve uygulama adını ekler.
3. **Firebase projesi** (console.firebase.google.com):
   - Authentication → Sign-in method → **E-posta/Şifre** aç.
   - Firestore Database → oluştur → konum **europe-west1** (Functions bölgesiyle aynı olmalı).
   - Functions için proje **Blaze** (kullandıkça öde) planına geçmeli; kullanım küçükken maliyet ~0'dır,
     yine de Google Cloud'da **bütçe uyarısı** kur.
4. **Firebase'i uygulamaya bağla:**
   ```
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure --project=PROJE_ID --platforms=android
   bash scripts/setup_android.sh com.SENIN.rota     # google-services.json artık var, eklentiyi bağlar
   ```
5. **Kurallar, indexler, functions:**
   ```
   firebase use PROJE_ID
   firebase deploy --only firestore
   cd functions && npm ci && npm run build && cd ..
   firebase deploy --only functions
   ```
5b. **Paylaşım bağlantıları (isteğe bağlı):** `firebase deploy --only hosting` ile `hosting/` klasörü yayınlanır
   (`https://PROJE_ID.web.app`). `hosting/*.html` içindeki `PLAY_STORE_URL`'yi Play bağlantınla değiştir.
   Uygulama bağlantısı için `SHARE_HOST=PROJE_ID.web.app bash scripts/setup_android.sh com.SENIN.rota`
   çalıştır ve uygulamayı `flutter run --dart-define=SHARE_BASE_URL=https://PROJE_ID.web.app` ile başlat.
   Yayın anahtarının SHA256 parmak izini `hosting/.well-known/assetlinks.json` içine yaz (Play App Signing parmak izi).
6. **Çalıştır:** `flutter pub get && flutter run` (telefon USB hata ayıklama açık ya da emulator).
   Telefonda "Firebase başlatılamadı" ekranı çıkarsa 4. adım eksik demektir.

## B. Test senaryoları (2 hesap gerekir: A = düzenleyen, B = katılan)

İki cihaz ya da biri telefon, biri emulator kullan. İkinci hesabı kayıt ekranından aç.

| # | Senaryo | Beklenen |
|---|---|---|
| 1 | A kayıt olur (18+ ve koşulları işaretler), e-postasına gelen bağlantıyı açar | Doğrulama ekranı otomatik ilerler, profil kurulumu açılır; profil sonrası Keşfet |
| 2 | A etkinlik oluşturur (kapasite 2) | Keşfet ve "Etkinliklerim"de görünür |
| 3 | B kayıt olur, A'nın etkinliğini bulur | Tam adres gizli, "Katılma isteği gönder" var |
| 4 | B istek gönderir | A'ya bildirim (uygulama içi + push) gelir |
| 5 | A isteği onaylar | B'ye bildirim gelir; B adresi ve sohbeti görür |
| 6 | İkisi sohbette yazışır | Mesajlar anında görünür |
| 7 | 2 kişi daha istek atıp A hepsini onaylamaya çalışır | Kapasite dolunca onay reddedilir |
| 8 | B etkinlikten ayrılır | Sayaç düşer, yer açılır |
| 9 | A etkinliği iptal eder | Katılımcılara bildirim, sohbet yazmaya kapanır |
| 10 | B, A'yı engeller / şikâyet eder | A'nın etkinlikleri B'de gizlenir; Firestore `reports`'ta kayıt oluşur |
| 11 | B hesabını siler (Ayarlar) | B'nin verileri, mesajları silinir; giriş artık yapılamaz |
| 12 | Keşfet'te arama çubuğuna "futbol", "kadikoy" yaz | Türkçe harf farkı yok sayılır, eşleşenler listelenir |
| 13 | Etkinlik oluştururken kategori seç | 148 kategori, gruplu ve aranabilir liste |
| 14 | Doğrulama bağlantısını açmadan giriş yap | Doğrulama ekranından öteye geçemez |
| 15 | Push: uygulama kapalıyken bildirime dokun | Etkinlik detayı açılır |

| 16 | Etkinlik dolunca üçüncü kullanıcı "Bekleme listesine katıl"a basar; biri ayrılır | Bekleyene "yer açıldı" bildirimi gelir |
| 17 | Başlamasına ~1 gün kala etkinlik | Sahip ve katılımcılara "24 saat içinde başlıyor" bildirimi (en geç 15 dk içinde) |
| 18 | Etkinlik oluştururken Tekrar: "Her hafta", 4 etkinlik | 4 ayrı etkinlik, "Tekrarlayan seri" etiketi |
| 19 | Düzenleyeni takip et; düzenleyen yeni etkinlik oluşturur | Takipçiye bildirim gelir |
| 20 | Grup kur, ikinci hesap katılır, grup için etkinlik oluştur | Üyeye "grup için yeni etkinlik" bildirimi |
| 21 | Etkinlik başladıktan sonra karşılıklı puan ver (en az 3 kişiyle) | Puan anonim; ortalama 3 puandan sonra görünür |
| 22 | Menüden Paylaş / Takvime ekle | Paylaşım metni (adres yok) / Google Takvim açılır |

Bir şey çalışmazsa: ekran görüntüsü + `flutter run` konsol çıktısı gönder.

## C. Bilinen sınırlar (bu sürüm)

- Para kazanma (öne çıkan etkinlik, işletme hesabı, reklam) henüz yok; ödeme altyapısı gerektirir.
- Zamanlanmış hatırlatma için Cloud Scheduler gerekir (Blaze plan; Functions deploy ile otomatik açılır).
- Haritadan konum seçme yok; adres yazılır, "Haritada aç" harici harita uygulamasını açar.
- Profil fotoğrafı yok. Google ile giriş yok (yalnızca e-posta/şifre). Sohbet mesajları için push yok.
- iOS yapılandırılmadı.
- Gizlilik metni taslak; boş alanları doldurup avukata kontrol ettir.


## Yeni arayüz (v2) için ek kontroller

1. **Storage'ı aç:** Firebase konsolu > Storage > Başla. Sonra `firebase deploy --only storage,firestore`.
2. **Fonksiyonlar:** Blaze planda `firebase deploy --only functions` (kaydedilen sayacı `onSavedWritten` ile çalışır).
3. **Elle dene:** ilk açılışta 4 karşılama sayfası; ana sayfada kategori/zaman çipleri; etkinlik oluştururken kapak fotoğrafı, süre, ücret notu, koşullar; detayda alttaki sabit "katıl" düğmesi; ortadaki "+" ile etkinlik oluştur; Ayarlar > Tema (açık/koyu/sistem); kalp ile kaydet ve Etkinliklerim > Kaydettiklerim; profilde Bireysel/Kurumsal seçimi.
4. **Henüz yok:** Google ile giriş (SHA-1 ve Firebase'de Google sağlayıcısı gerekir), kurumsal vergi doğrulaması, öne çıkarma/reklam.
