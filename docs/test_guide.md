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

Bir şey çalışmazsa: ekran görüntüsü + `flutter run` konsol çıktısı gönder.

## C. Bilinen sınırlar (bu sürüm)

- Haritadan konum seçme yok; adres yazılır, "Haritada aç" harici harita uygulamasını açar.
- Profil fotoğrafı yok. Google ile giriş yok (yalnızca e-posta/şifre). Sohbet mesajları için push yok.
- iOS yapılandırılmadı.
- Gizlilik metni taslak; boş alanları doldurup avukata kontrol ettir.
