import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Karşılama ekranlarının görülüp görülmediği. `null` = henüz okunuyor.
class OnboardingController extends StateNotifier<bool?> {
  OnboardingController() : super(null) {
    _load();
  }

  static const String storageKey = 'onboarding_seen';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(storageKey) ?? false;
      if (mounted) state = seen;
    } catch (_) {
      if (mounted) state = true; // Okunamazsa kullanıcıyı engelleme.
    }
  }

  Future<void> markSeen() async {
    state = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(storageKey, true);
    } catch (_) {
      // Kaydedilemese bile bu oturumda tekrar gösterilmez.
    }
  }
}

final onboardingSeenProvider =
    StateNotifierProvider<OnboardingController, bool?>(
  (ref) => OnboardingController(),
);
