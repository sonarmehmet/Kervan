import 'package:flutter/material.dart';

/// Kullanım koşulları ve topluluk kuralları.
///
/// DİKKAT: Metin TASLAKTIR; yayından önce bir avukata kontrol ettir ve
/// `docs/site/terms.html` ile birlikte güncel tut.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const List<(String, String)> sections = <(String, String)>[
    (
      'Kimler kullanabilir?',
      'Rota\'yı yalnızca 18 yaşını doldurmuş kişiler kullanabilir. Kayıt olurken verdiğin '
          'bilgilerin doğru olduğunu kabul edersin.',
    ),
    (
      'Rota nedir?',
      'Rota, birlikte aktivite yapmak isteyen insanları bir araya getiren bir platformdur. '
          'Etkinlikleri kullanıcılar düzenler; Rota etkinliklerin düzenleyicisi, tarafı veya '
          'sorumlusu değildir.',
    ),
    (
      'Topluluk kuralları',
      'Taciz, nefret söylemi, tehdit, dolandırıcılık, spam, yasa dışı faaliyet ve cinsel içerikli '
          'etkinlikler yasaktır. Başkası adına hesap açamaz, sahte etkinlik oluşturamazsın. '
          'Kuralları ihlal eden içerik kaldırılır, hesaplar kısıtlanabilir veya kapatılabilir.',
    ),
    (
      'Güvenliğin için',
      'Yeni tanıştığın kişilerle ilk buluşmaları kalabalık ve herkese açık yerlerde yap. '
          'Yakınlarına nereye gittiğini haber ver. Kişisel bilgilerini (ev adresi, finansal bilgiler) '
          'paylaşma. Kendini rahatsız hissedersen buluşmadan ayrıl; kullanıcıyı şikâyet et veya engelle.',
    ),
    (
      'Sorumluluk',
      'Etkinliklere katılım kendi sorumluluğundadır. Rota, kullanıcıların davranışlarından ve '
          'etkinliklerde yaşanan olaylardan kaynaklanan zararlardan, yasaların izin verdiği ölçüde, '
          'sorumlu tutulamaz.',
    ),
    (
      'Hesabın',
      'Hesabını istediğin zaman Ayarlar → Hesabı sil ile silebilirsin. Şifreni kimseyle paylaşma.',
    ),
    (
      'Değişiklikler',
      'Bu koşullar güncellenebilir. Önemli değişiklikleri uygulama içinde duyururuz.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanım koşulları')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (final (title, body) in sections) ...[
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
