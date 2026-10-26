import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/services/firebase_providers.dart';
import '../../authentication/data/auth_repository.dart';

/// Push bildirimi (FCM) kaydı. Jeton `users/{uid}/fcmTokens/{token}` altında tutulur;
/// gönderimi Cloud Functions (`onNotificationCreated`) yapar.
/// Bildirim izni reddedilirse uygulama içi bildirim listesi yine çalışır.
class PushService {
  PushService(this._messaging, this._firestore);

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  StreamSubscription<String>? _refreshSubscription;
  String? _registeredUid;

  String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  Future<void> _saveToken(String uid, String token) {
    return _firestore.doc(FirestorePaths.userFcmToken(uid, token)).set(
      <String, dynamic>{
        'platform': _platform,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  /// İzin ister, jetonu kaydeder ve jeton yenilenince tekrar kaydeder. Hataları yutar (loglar).
  Future<void> registerForUser(String uid) async {
    if (_registeredUid == uid) return;
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await _messaging.getToken();
      if (token != null) await _saveToken(uid, token);
      _registeredUid = uid;

      await _refreshSubscription?.cancel();
      _refreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
        unawaited(
          _saveToken(uid, newToken).catchError((Object error) {
            debugPrint('Push jetonu yenilenemedi: $error');
          }),
        );
      });
    } catch (error) {
      debugPrint('Push kaydı başarısız: $error');
    }
  }

  /// Çıkış yapmadan ÖNCE çağrılır: bu cihazın jetonunu kullanıcıdan ayırır.
  Future<void> unregister(String uid) async {
    await _refreshSubscription?.cancel();
    _refreshSubscription = null;
    _registeredUid = null;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.doc(FirestorePaths.userFcmToken(uid, token)).delete();
      }
    } catch (error) {
      debugPrint('Push jetonu silinemedi: $error');
    }
  }

  Future<void> dispose() async {
    await _refreshSubscription?.cancel();
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(
    FirebaseMessaging.instance,
    ref.watch(firestoreProvider),
  );
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

/// Oturum açılınca push kaydını yapar. `RotaApp` içinde izlenir.
final pushRegistrationProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<User?>>(
    authStateProvider,
    (previous, next) {
      final user = next.valueOrNull;
      if (user != null && user.emailVerified) {
        unawaited(ref.read(pushServiceProvider).registerForUser(user.uid));
      }
    },
    fireImmediately: true,
  );
});
