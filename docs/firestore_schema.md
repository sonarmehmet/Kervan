# Rota — Firestore Veri Şeması (ORTAK SÖZLEŞME)

Bu dosya üç geliştiricinin (A, B, C) uyması gereken tek doğru kaynaktır.
`firestore.rules` bu şemaya göre yazılmıştır. Şemayı değiştirmek için önce bu dosya
ve `firestore.rules` birlikte güncellenmeli, değişiklik PR açıklamasında belirtilmelidir.

Tüm alan adları İngilizce, `camelCase`. Tarihler Firestore `Timestamp`.

---

## 1. `users/{uid}`

`uid` = Firebase Auth kullanıcı kimliği. E-posta ve telefon bu belgede TUTULMAZ.

| Alan | Tip | Kural |
|---|---|---|
| displayName | string | 2–40 karakter |
| bio | string | 0–280 karakter |
| city | string | 0–40 karakter |
| interests | list<string> | en fazla 10 |
| createdAt | timestamp | oluşturma anı, sonradan DEĞİŞMEZ |
| updatedAt | timestamp | isteğe bağlı |

Alt koleksiyon: `users/{uid}/blocks/{blockedUid}` — alanlar: `createdAt` (timestamp).
Yalnızca `uid` sahibi okur/yazar.

Alt koleksiyon: `users/{uid}/fcmTokens/{token}` — belge kimliği FCM jetonunun kendisi.
Alanlar: `platform` (`android` | `ios`), `updatedAt` (sunucu zamanı). Yalnızca `uid` sahibi yazar/okur/siler.
Push gönderimini `onNotificationCreated` Cloud Function'ı yapar; geçersiz jetonları siler.

Silme: istemci silemez. Hesap silme `deleteAccount` Cloud Function ile yapılır.

## 2. `events/{eventId}`

| Alan | Tip | Kural |
|---|---|---|
| ownerId | string | oluşturanın uid'i, DEĞİŞMEZ |
| ownerName | string | 1–40 karakter (listelerde ek okuma gerekmesin diye kopya) |
| title | string | 3–80 |
| description | string | 0–1000 |
| category | string | `EventCategory.id` değerlerinden biri |
| city | string | 2–30, `turkey_cities.dart` içinden |
| district | string | 0–40; herkese açık YAKLAŞIK konum |
| startsAt | timestamp | oluşturmada gelecekte olmalı |
| capacity | int | 1–100; `acceptedCount` değerinin altına düşürülemez |
| acceptedCount | int | oluşturmada 0; SADECE Cloud Functions artırır/azaltır |
| status | string | `active` veya `cancelled` (active → cancelled tek yönlü) |
| createdAt | timestamp | sunucu zamanı (`FieldValue.serverTimestamp()`) |
| updatedAt | timestamp | isteğe bağlı |

Not: `acceptedCount` istemciden güncellenemez. Kural, güncellemede bu alanın
değişmesine izin vermez; sahibin yazabildiği alanlar kuralda listelenmiştir.

### 2.1 `events/{eventId}/private/location`

Tek belge, sabit kimlik `location`. Alan: `address` (string, 3–200).
Okuma: etkinlik sahibi ve onaylı katılımcılar. Yazma: yalnızca sahip.
Etkinlik oluşturulurken `events/{id}` ve `private/location` TEK `WriteBatch` ile yazılır.

### 2.2 `events/{eventId}/requests/{userId}`

Belge kimliği = isteği gönderenin uid'i (bir kullanıcı bir etkinliğe tek talep).

| Alan | Tip | Kural |
|---|---|---|
| userId | string | = belge kimliği = gönderenin uid'i |
| userName | string | 1–40 |
| status | string | `pending`, `approved`, `rejected`, `cancelled` |
| createdAt | timestamp | sunucu zamanı |

İstemci yalnızca: yeni talep oluşturur (`pending`), `pending → cancelled` ve
`cancelled → pending` geçişini yapar. `approved` ve `rejected` SADECE Cloud Functions.

### 2.3 `events/{eventId}/participants/{userId}`

Yalnızca Cloud Functions yazar. Alanlar: `userId`, `userName`, `joinedAt`.
Okuma: kişinin kendisi, sahip, diğer onaylı katılımcılar.

### 2.4 `events/{eventId}/messages/{messageId}`

Etkinlik sohbeti. Alanlar: `senderId`, `text` (1-500), `createdAt` (= sunucu zamanı).
Gönderen adı SAKLANMAZ; istemci adı sahip adı + katılımcı listesinden çözer (taklit riskini önler).
Okuma/yazma: yalnızca sahip ve onaylı katılımcılar; yazma yalnızca etkinlik `active` iken.
Güncelleme yok; silme: gönderen veya etkinlik sahibi. Hesap silinince mesajlar silinir.

## 3. `notifications/{uid}/items/{itemId}`

Yalnızca Cloud Functions oluşturur. Kullanıcı yalnızca `read` alanını günceller.

| Alan | Tip |
|---|---|
| type | string: `request_received`, `request_approved`, `request_rejected`, `event_cancelled` |
| eventId | string |
| eventTitle | string |
| read | bool |
| createdAt | timestamp |

## 4. `reports/{reportId}`

İstemci yalnızca oluşturur, okuyamaz.

| Alan | Tip | Kural |
|---|---|---|
| reporterId | string | = oturum açan uid |
| targetType | string | `event` veya `user` |
| targetId | string | 1–128 |
| reason | string | `spam`, `harassment`, `unsafe`, `fake`, `other` |
| details | string | 0–500 |
| status | string | oluşturmada `open` |
| createdAt | timestamp | sunucu zamanı |

---

## Cloud Functions sözleşmesi (callable, bölge: `europe-west1`)

| Fonksiyon | Giriş | Çıkış | İş |
|---|---|---|---|
| `approveRequest` | `{eventId, userId}` | `{ok: true}` | Sahip kontrolü, transaction ile kapasite kontrolü, `participants` yaz, `acceptedCount++`, talebi `approved` yap, bildirim üret |
| `rejectRequest` | `{eventId, userId}` | `{ok: true}` | Sahip kontrolü, talebi `rejected` yap, bildirim üret |
| `leaveEvent` | `{eventId}` | `{ok: true}` | Onaylı katılımcıyı çıkar, `acceptedCount--`, talebi `cancelled` yap |
| `cancelEvent` | `{eventId}` | `{ok: true}` | Sahip kontrolü, etkinliği `cancelled` yap, katılımcılara bildirim |
| `deleteAccount` | `{}` | `{ok: true}` | Profil, engeller, bildirimler ve Auth kaydını sil; sahip olduğu aktif etkinlikleri iptal et |

Hata kodları: `unauthenticated`, `permission-denied`, `not-found`, `failed-precondition`
(kapasite dolu, etkinlik iptal, tarih geçmiş), `invalid-argument`.

Tetikleyici: `events/{eventId}/requests/{userId}` oluşturulunca sahibe `request_received` bildirimi.
Push (FCM) gönderimi aşama 7'de bildirim belgesi oluşunca yapılır.

---

## Ortak sabitler (Dart tarafı, `lib/core/constants/`)

- `firestore_paths.dart`: koleksiyon adları ve yardımcı fonksiyonlar (`eventDoc(id)` gibi). Elle yazılmış string kullanılmaz.
- `event_categories.dart`: `EventCategory` listesi. İlk sürüm kimlikleri: `sport`, `yoga`, `walking`, `hiking`, `cycling`, `coffee`, `games`, `music`, `art`, `learning`, `volunteering`, `other`.
- `turkey_cities.dart`: 81 il listesi.

## Sorgu kalıpları (indexler `firestore.indexes.json` içinde)

- Keşif: `status == active`, isteğe bağlı `city ==`, `category ==`, `startsAt >= now`, `orderBy startsAt`.
- Oluşturduklarım: `ownerId ==`, `orderBy startsAt desc`.
- Katıldıklarım: `collectionGroup('participants').where('userId' == uid)` sonra etkinlikleri `get` ile çek.
- Engellenen kullanıcıların etkinlikleri istemcide filtrelenir (Firestore `not-in` sınırı nedeniyle).
