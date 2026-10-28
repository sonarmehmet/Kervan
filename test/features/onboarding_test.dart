import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/onboarding/onboarding_controller.dart';
import 'package:rota/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('karşılama görüldü bilgisi saklanır', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingSeenProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(onboardingSeenProvider), false);

    await container.read(onboardingSeenProvider.notifier).markSeen();
    expect(container.read(onboardingSeenProvider), true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(OnboardingController.storageKey), true);
  });

  testWidgets('karşılama sayfaları ileri ile ilerler', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
    );
    expect(find.text(onboardingPages.first.title), findsOneWidget);
    await tester.tap(find.text('İleri'));
    await tester.pumpAndSettle();
    expect(find.text(onboardingPages[1].title), findsOneWidget);
  });
}
