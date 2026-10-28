# Rota

Aktivite etkinlikleri için sosyal uygulama (Flutter + Firebase). Kullanıcılar etkinlik oluşturur, diğerleri katılma isteği
gönderir, düzenleyen onaylar veya reddeder.

**Özellikler:** e-posta doğrulamalı kayıt/giriş, 148 kategori, arama ve filtre, kapasite (eşzamanlı onaylarda taşma yok),
etkinlik sohbeti, bildirimler (FCM), engelle/şikâyet, bekleme listesi, hatırlatmalar (24 saat/1 saat), tekrarlayan etkinlik,
düzenleyen takibi, gruplar, paylaşım bağlantısı + takvime ekleme, anonim karşılıklı değerlendirme (1-5 yıldız).

**Mimari:** feature-first, Riverpod, GoRouter, Material 3. Yetkiler Firestore kuralları ve Cloud Functions'ta (europe-west1) zorlanır.

Kurulum ve test: `docs/test_guide.md` · Veri modeli: `docs/firestore_schema.md` · Yayın: `docs/release_checklist.md`
