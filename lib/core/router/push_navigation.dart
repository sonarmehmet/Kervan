import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/data/auth_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import 'app_router.dart';
import 'route_names.dart';

/// Push bildirimine dokununca ilgili etkinliği açar.
/// - Uygulama arka plandaysa: `onMessageOpenedApp`
/// - Uygulama kapalıyken bildirimle açıldıysa: `getInitialMessage`; oturum ve profil yüklenince açılır.
/// Sunucu (`send_push.ts`) bildirim verisine `eventId` koyar.
/// `KervanApp` içinde izlenir.
final pushNavigationProvider = Provider<void>((ref) {
  final router = ref.watch(appRouterProvider);

  final subscription = FirebaseMessaging.onMessageOpenedApp.listen(
    (message) => _openEvent(router, message),
  );
  ref.onDispose(subscription.cancel);

  unawaited(() async {
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial == null) return;
      await ref
          .read(authStateProvider.future)
          .timeout(const Duration(seconds: 15));
      final profile = await ref
          .read(currentProfileProvider.future)
          .timeout(const Duration(seconds: 15));
      if (profile != null) _openEvent(router, initial);
    } catch (error) {
      debugPrint('Bildirimden açılış işlenemedi: $error');
    }
  }());
});

void _openEvent(GoRouter router, RemoteMessage message) {
  final eventId = message.data['eventId'];
  if (eventId is String && eventId.isNotEmpty) {
    unawaited(router.push<void>(RoutePaths.eventDetails(eventId)));
  }
}
