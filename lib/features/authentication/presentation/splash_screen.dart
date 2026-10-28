import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../profile/data/profile_repository.dart';
import '../data/auth_repository.dart';
import '../data/session_service.dart';

/// Oturum ve profil bilgisi yüklenirken gösterilir. Yükleme hatası olursa tekrar deneme sunar.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final profile = ref.watch(currentProfileProvider);

    final error = auth.error ?? profile.error;
    if (error != null) {
      return Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ErrorView(
              message: mapErrorToMessage(error),
              onRetry: () {
                ref.invalidate(authStateProvider);
                ref.invalidate(currentProfileProvider);
              },
            ),
            TextButton(
              onPressed: () => ref.read(sessionServiceProvider).signOut(),
              child: const Text('Çıkış yap'),
            ),
          ],
        ),
      );
    }
    return const Scaffold(body: LoadingView());
  }
}
