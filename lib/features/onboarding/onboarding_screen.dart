import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/rota_colors.dart';
import 'onboarding_controller.dart';

class OnboardingPage {
  const OnboardingPage(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;
}

const List<OnboardingPage> onboardingPages = [
  OnboardingPage(
    Icons.explore,
    'Yakınındaki etkinlikleri keşfet',
    '148 kategoride; kahve buluşmasından doğa yürüyüşüne, oyun gecesinden konsere kadar her şey burada.',
  ),
  OnboardingPage(
    Icons.add_circle,
    'Kendi etkinliğini oluştur',
    'Tarih, yer ve kapasiteyi belirle, kapak fotoğrafı ekle. Katılım taleplerini sen onayla.',
  ),
  OnboardingPage(
    Icons.how_to_reg,
    'Güvenle katıl',
    'Talep gönder, onaylanınca sohbete ve tam adrese eriş. Yer yoksa bekleme listesine gir.',
  ),
  OnboardingPage(
    Icons.star,
    'Anonim puanla, topluluğu büyüt',
    'Etkinlik sonrası birbirinizi anonim puanlayın; güvenilir düzenleyicileri takip edin.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (mounted) context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _index == onboardingPages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Atla'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingPages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = onboardingPages[i];
                  final bg = RotaColors.accentAt(i);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: bg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 80,
                            color: RotaColors.onAccent(bg),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.text,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < onboardingPages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: last
                      ? _finish
                      : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                  child: Text(last ? 'Başla' : 'İleri'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
