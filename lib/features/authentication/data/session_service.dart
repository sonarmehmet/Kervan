import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/data/push_service.dart';
import 'auth_repository.dart';

/// Oturum kapatma: önce bu cihazın push jetonunu kullanıcıdan ayırır, sonra çıkış yapar.
/// Böylece çıkış yapan kullanıcının bildirimleri cihaza gelmeye devam etmez.
class SessionService {
  SessionService(this._auth, this._push);

  final AuthRepository _auth;
  final PushService _push;

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _push.unregister(uid);
    }
    await _auth.signOut();
  }
}

final sessionServiceProvider = Provider<SessionService>(
  (ref) => SessionService(
    ref.watch(authRepositoryProvider),
    ref.watch(pushServiceProvider),
  ),
);
