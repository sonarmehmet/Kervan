# Rota Gizlilik Politikası ve KVKK Aydınlatma Metni — TASLAK

> **UYARI:** Bu metin hukuki danışmanlık değildir; bir başlangıç taslağıdır. Yayınlamadan önce bir avukata
> veya KVKK uzmanına inceletin, köşeli parantezli `[...]` alanları kendi bilgilerinizle doldurun.
> Metin, uygulamanın bu sürümdeki gerçek davranışına göre yazılmıştır; özellik ekledikçe güncelleyin.

**Son güncelleme:** [GG.AA.YYYY]

## 1. Veri sorumlusu

Veri sorumlusu: [Ad Soyad / Şirket Unvanı]
Adres: [Adres]
İletişim: [e-posta adresi]

## 2. Hangi verileri işliyoruz?

| Veri | Nasıl elde edilir | Kimler görebilir |
|---|---|---|
| E-posta adresi | Kayıt sırasında sen girersin | Yalnızca sen ve sistem (Firebase Authentication). Diğer kullanıcılara gösterilmez. |
| Ad, şehir, hakkında yazısı, ilgi alanları | Profil oluştururken sen girersin | Uygulamaya giriş yapmış tüm kullanıcılar |
| Etkinlik bilgileri (başlık, açıklama, kategori, tarih, şehir, ilçe, kapasite) | Etkinlik oluşturduğunda | Giriş yapmış tüm kullanıcılar |
| Etkinlik buluşma adresi (tam adres) | Etkinlik oluştururken sen yazarsın | Yalnızca etkinlik sahibi ve katılımı onaylanan kişiler |
| Katılım talepleri ve katılımcı listesi | Talep gönderdiğinde | Talep sahibi ve etkinlik sahibi; katılımcı listesini sahip ve onaylı katılımcılar |
| Etkinlik sohbeti mesajları | Sohbette yazdığında | Yalnızca etkinlik sahibi ve onaylı katılımcılar |
| Bildirimler | Uygulama olaylarından üretilir | Yalnızca ilgili kullanıcı |
| Engellenen kullanıcılar | Sen engellediğinde | Yalnızca sen |
| Şikâyetler | Sen şikâyet ettiğinde | Yalnızca uygulama yöneticileri |
| Bildirim jetonu (FCM) ve cihaz platformu | Bildirim izni verdiğinde | Yalnızca sistem; push bildirimi göndermek için kullanılır |

Kesin GPS konumun **toplanmaz**. Adres, etkinlik sahibinin kendi yazdığı metindir.

## 3. İşleme amaçları ve hukuki sebepler

- Hesap oluşturma ve uygulamayı çalıştırma: sözleşmenin ifası.
- Etkinlik eşleştirme, katılım yönetimi, bildirim gönderme: sözleşmenin ifası.
- Güvenlik, kötüye kullanımın önlenmesi, şikâyetlerin incelenmesi: meşru menfaat.
- Hukuki yükümlülüklerin yerine getirilmesi: kanuni yükümlülük.
- Bildirim izni: açık rıza (izni işletim sistemi ayarlarından istediğin zaman kapatabilirsin).

## 4. Verilerin aktarılması

Verileriniz Google LLC'nin Firebase hizmetlerinde (Authentication, Cloud Firestore, Cloud Functions,
Cloud Messaging) işlenir ve saklanır. Sunucular [Avrupa — europe-west1] bölgesindedir; hizmet sağlayıcının
altyapısı nedeniyle yurt dışına aktarım söz konusu olabilir. Verileriniz satılmaz ve reklam amacıyla
paylaşılmaz.

## 5. Saklama süresi

Hesabınız açık olduğu sürece saklanır. Hesabınızı sildiğinizde profil, engel listesi, bildirimler, sohbet mesajları ve
gönderdiğiniz katılım talepleri silinir; oluşturduğunuz etkinlikler iptal edilir, sahip adı "Silinmiş kullanıcı"
olarak anonimleştirilir ve tam adres silinir. Şikâyet kayıtları, güvenlik amacıyla [süre] boyunca saklanabilir.

## 6. Haklarınız (KVKK madde 11)

Verilerinizin işlenip işlenmediğini öğrenme, bilgi talep etme, düzeltme, silme/yok etme, aktarılan üçüncü
kişileri öğrenme, itiraz etme ve zarar halinde tazminat talep etme haklarına sahipsiniz.
Başvuru: [e-posta adresi]

## 7. Hesap ve veri silme

- Uygulama içinde: Profil → Ayarlar → **Hesabı sil**.
- Uygulamaya erişemiyorsanız: [e-posta adresi] adresine, kayıtlı e-postanızı belirterek silme talebi gönderin.
  Talepler [30] gün içinde sonuçlandırılır.

## 8. Çocuklar

Rota 18 yaşından küçüklere yönelik değildir. 18 yaşından küçük bir kullanıcının hesabını fark edersek sileriz.

## 9. Güvenlik

Veriler aktarım sırasında şifrelenir (HTTPS/TLS). Erişim, sunucu tarafında güvenlik kurallarıyla sınırlandırılmıştır.
Hiçbir sistem tamamen risksizdir; bir ihlal olursa ilgili mevzuata uygun şekilde bildirim yaparız.

## 10. Değişiklikler

Bu politika güncellenebilir. Önemli değişiklikleri uygulama içinde duyururuz.
