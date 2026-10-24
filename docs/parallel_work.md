# Kervan — Üç Claude ile Paralel Çalışma Planı

## Altın kurallar

1. Herkes yalnızca KENDİ klasörlerine dokunur (aşağıdaki tablo).
2. Ortak dosyalar (`pubspec.yaml`, `lib/core/**`, `firestore.rules`, `firestore.indexes.json`,
   `docs/firestore_schema.md`) sahibinin dışında değiştirilmez. İhtiyaç varsa PR açıklamasına
   "Ortak dosya isteği" başlığıyla yazılır.
3. Her Claude kendi dalında çalışır, bitince Pull Request açar. `main`'e doğrudan push yok.
4. Veri modelleri `docs/firestore_schema.md`'ye birebir uyar. Şemadan sapma gerekiyorsa önce dur, kullanıcıya sor.
5. Kod, değişken, dosya adları İngilizce. Kullanıcıya açıklamalar Türkçe.
6. Test sonuçları uydurulmaz. Flutter/Node çalıştırılamıyorsa bunu açıkça yaz.
7. Gizli anahtar, sahte Firebase kimliği veya `firebase_options.dart` içeriği üretilmez.

## Sahiplik tablosu

| Alan | Sahibi |
|---|---|
| `lib/core/**`, `lib/main.dart`, `lib/app.dart`, `pubspec.yaml` | **A** |
| `lib/features/authentication`, `profile`, `settings`, `moderation` | **A** |
| `lib/features/event_creation`, `event_details`, `event_discovery`, `location` | **B** |
| `lib/features/participation`, `notifications` | **C** |
| `functions/**`, `firestore.rules`, `firestore.indexes.json`, `rules_test/**` | **C** |
| `docs/firestore_schema.md` | Değişiklik C + A onayıyla |

## Başlangıç sırası

0. Kullanıcı GitHub'da private `kervan` deposu açar, bu klasörü yükler (`main`).
1. **A önce** `core/` iskeletini ve `lib/core/constants/` dosyalarını yazıp `main`'e PR ile birleştirir
   (tema, router, ortak widget'lar, `firestore_paths.dart`, `event_categories.dart`, `turkey_cities.dart`).
   B ve C bu sırada şu işleri yapabilir: B model sınıflarını (`Event`), C Cloud Functions ve rules.
2. Core `main`'e girince B ve C dallarını `main`'den güncelleyip ekran işlerine geçer.
3. Her aşama sonunda birleştirme sırası: A → C → B.

---

## Claude A için başlangıç talimatı

```
Sen Kervan adlı Flutter + Firebase sosyal etkinlik uygulamasının A bölümünden sorumlusun
(hesap ve güvenlik). Benimle tamamen Türkçe konuş; kod, dosya ve değişken adları İngilizce.

Önce şunları oku: docs/firestore_schema.md, docs/parallel_work.md, firestore.rules, pubspec.yaml.

Dalın: feat/accounts. Yalnızca şu yerlere dokunabilirsin:
lib/core/**, lib/main.dart, lib/app.dart, pubspec.yaml,
lib/features/authentication, profile, settings, moderation, ve bunların testleri.

Teknoloji: Flutter, Dart, Material 3, Riverpod, GoRouter, Firebase Auth, Cloud Firestore.
Mimari: feature-first, her özellik içinde data/ ve presentation/. Gereksiz soyutlama yok.

Sırayla yap:
1. core: Material 3 tema (açık/koyu), GoRouter (giriş kontrolü + alt gezinme: Keşfet, Etkinliklerim,
   Bildirimler, Profil), ortak widget'lar (loading, error, empty), firebase_providers.dart,
   firestore_paths.dart, event_categories.dart, turkey_cities.dart, hata eşleme. Bunu önce PR yap.
2. authentication: e-posta/şifre kayıt-giriş-şifre sıfırlama, Türkçe hata mesajları.
3. profile: profil oluşturma/düzenleme, ilgi alanları, şemaya uygun users/{uid} yazımı.
4. settings: çıkış, hesap silme (deleteAccount callable'ını çağırır), gizlilik politikası ekranı.
5. moderation: kullanıcı engelleme (users/{uid}/blocks), şikâyet formu (reports), engelli listesi.

Kurallar: yetkileri yalnızca arayüzde kontrol etme; şemadan sapma; sahte Firebase kimliği üretme;
test sonucu uydurma. Flutter çalıştırılamıyorsa bunu açıkça söyle. İş bitince PR aç ve
tamamlanan/kalan işleri Türkçe raporla.
```

## Claude B için başlangıç talimatı

```
Sen Kervan adlı Flutter + Firebase sosyal etkinlik uygulamasının B bölümünden sorumlusun
(etkinlikler). Benimle tamamen Türkçe konuş; kod, dosya ve değişken adları İngilizce.

Önce şunları oku: docs/firestore_schema.md, docs/parallel_work.md, firestore.rules, pubspec.yaml.

Dalın: feat/events. Yalnızca şu yerlere dokunabilirsin:
lib/features/event_creation, event_details, event_discovery, location, ve bunların testleri.
core/ henüz yoksa A'nın PR'ını bekle; beklerken sadece Event modelini ve repository'leri yaz.

Teknoloji: Flutter, Dart, Material 3, Riverpod, GoRouter, Cloud Firestore.

Sırayla yap:
1. event_details/data: Event modeli (fromFirestore/toMap), şemaya birebir.
2. event_creation: etkinlik oluşturma/düzenleme/iptal formu. Etkinlik + private/location TEK WriteBatch.
   İptal için cancelEvent callable'ını çağır. Form doğrulaması kuraldaki sınırlarla aynı olsun.
3. event_discovery: liste, şehir/kategori/tarih filtreleri (indexler firestore.indexes.json'da),
   engellenen kullanıcıların etkinliklerini istemcide filtrele, sayfalama.
4. event_details: detay ekranı, kapasite göstergesi, konum yalnızca onaylı katılımcıya/sahibe görünür,
   "Etkinliklerim" (oluşturduklarım + katıldıklarım) ekranı.
5. location: şimdilik şehir/ilçe seçimi ve adres metni. Harita eklentisi aşama 7'de, API anahtarı
   kullanıcıdan istenecek; sahte anahtar yazma.

Katılım butonları için C'nin participation feature'ına bağlan; onun arayüzünü kendin yazma.
Kurallar: şemadan sapma; test sonucu uydurma; Flutter çalıştırılamıyorsa açıkça söyle.
İş bitince PR aç ve tamamlanan/kalan işleri Türkçe raporla.
```

## Claude C için başlangıç talimatı

```
Sen Kervan adlı Flutter + Firebase sosyal etkinlik uygulamasının C bölümünden sorumlusun
(katılım sistemi ve sunucu tarafı). Benimle tamamen Türkçe konuş; kod, dosya ve değişken adları İngilizce.

Önce şunları oku: docs/firestore_schema.md, docs/parallel_work.md, firestore.rules, firebase.json.

Dalın: feat/participation. Yalnızca şu yerlere dokunabilirsin:
functions/**, firestore.rules, firestore.indexes.json, rules_test/**,
lib/features/participation, lib/features/notifications, ve bunların testleri.

Teknoloji: Cloud Functions (TypeScript, firebase-functions v2, bölge europe-west1), Firestore transaction,
Firebase Emulator ile kural testleri, Flutter + Riverpod arayüzü.

Sırayla yap:
1. functions/: package.json, tsconfig.json, src/index.ts ve şemadaki callable'lar:
   approveRequest, rejectRequest, leaveEvent, cancelEvent, deleteAccount. Kapasite kontrolü ve
   acceptedCount güncellemesi TEK Firestore transaction içinde olmalı (yarış durumu olmamalı).
   Talep oluşunca sahibe bildirim üreten tetikleyici.
2. rules_test/: @firebase/rules-unit-testing ile firestore.rules testleri (yetkisiz yazma,
   kapasite alanına dokunma, konum gizliliği, başkasının talebine erişim).
3. participation (Flutter): katılım talebi gönderme/geri çekme, sahip için talep listesi (onayla/reddet
   callable'ları), katılımcı listesi, etkinlikten ayrılma.
4. notifications (Flutter): bildirim listesi, okundu işareti. FCM push entegrasyonu aşama 7'de;
   google-services.json kullanıcıdan istenecek, sahte yapılandırma üretme.

Kurallar: kural ve fonksiyonlar yetkiyi sunucuda zorlamalı; şemadan sapma; test sonucu uydurma;
npm veya emulator çalıştırılamıyorsa açıkça söyle. İş bitince PR aç ve tamamlanan/kalan işleri
Türkçe raporla.
```

## Birleştirme kontrol listesi (kullanıcı için)

- [ ] A'nın core PR'ı `main`'e girdi mi?
- [ ] B ve C dallarını `main`'den güncelledi mi? (`git merge main`)
- [ ] Şema değişikliği oldu mu? Olduysa `firestore.rules` ile birlikte mi güncellendi?
- [ ] `flutter analyze` ve `flutter test` (kendi bilgisayarında) temiz mi?
- [ ] Firebase emulator ile `rules_test` geçti mi?
