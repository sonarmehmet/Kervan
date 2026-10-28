import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rota/core/theme/app_theme.dart';
import 'package:rota/core/theme/rota_colors.dart';
import 'package:rota/core/theme/theme_mode_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('açık ve koyu tema üretilir, ana renkler paletten gelir', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.colorScheme.primary, RotaColors.ink);
    expect(AppTheme.light.colorScheme.surface, RotaColors.paper);
    expect(AppTheme.dark.colorScheme.surface, RotaColors.nightPaper);
    expect(AppTheme.dark.colorScheme.primary, RotaColors.nightInk);
  });

  test('onAccent zemine göre okunur renk seçer', () {
    expect(RotaColors.onAccent(RotaColors.sun), RotaColors.ink);
    expect(RotaColors.onAccent(RotaColors.plum), RotaColors.paper);
  });

  test('tema modu kodlama ve çözme', () {
    for (final mode in ThemeMode.values) {
      expect(ThemeModeController.decode(ThemeModeController.encode(mode)), mode);
    }
    expect(ThemeModeController.decode(null), ThemeMode.system);
    expect(ThemeModeController.decode('bozuk'), ThemeMode.system);
  });

  test('tema tercihi cihazda saklanır ve geri yüklenir', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(themeModeProvider), ThemeMode.system);

    await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ThemeModeController.storageKey), 'dark');

    final second = ProviderContainer();
    addTearDown(second.dispose);
    second.read(themeModeProvider); // yüklemeyi başlatır
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(second.read(themeModeProvider), ThemeMode.dark);
  });
}
