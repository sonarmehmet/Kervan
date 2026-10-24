import 'package:flutter/material.dart';

/// Gizlilik politikası ekranı.
///
/// DİKKAT: Aşağıdaki metin YER TUTUCUDUR ve hukuki metin değildir.
/// Google Play ve App Store yayınından önce KVKK'ya uygun gerçek politika metniyle
/// değiştirilmeli (ayrıca internette herkese açık bir adreste de yayınlanmalı).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Gizlilik politikası')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Bu metin geçicidir. Yayından önce gerçek gizlilik politikasıyla değiştirilmelidir.',
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Hangi verileri topluyoruz?', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'E-posta adresin, profil bilgilerin (ad, şehir, hakkında yazısı, ilgi alanları), '
            'oluşturduğun etkinlikler, katılım taleplerin ve etkinlik konumları.',
          ),
          const SizedBox(height: 16),
          Text('Konum gizliliği', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Etkinliklerin tam adresi yalnızca etkinlik sahibi ve onaylanan katılımcılar tarafından görülür. '
            'Diğer kullanıcılar yalnızca şehir ve ilçeyi görür.',
          ),
          const SizedBox(height: 16),
          Text('Hesap silme', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Ayarlar bölümünden hesabını istediğin zaman silebilirsin. '
            'Profil bilgilerin ve bildirimlerin kalıcı olarak silinir.',
          ),
        ],
      ),
    );
  }
}
