import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/firebase_providers.dart';

/// Firebase Authentication işlemleri. Ekranlar FirebaseAuth'u doğrudan çağırmaz.
class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Hesap açar ve doğrulama e-postası gönderir. E-posta gönderimi başarısız olsa bile
  /// hesap açılmıştır; kullanıcı doğrulama ekranından tekrar gönderebilir.
  Future<void> register({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    try {
      await credential.user?.sendEmailVerification();
    } catch (_) {
      // Doğrulama ekranındaki "tekrar gönder" düğmesi devreye girer.
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException('Oturum bulunamadı. Lütfen tekrar giriş yap.');
    }
    await user.sendEmailVerification();
  }

  /// Kullanıcıyı sunucudan yeniler; doğrulandıysa kimlik jetonunu da yeniler
  /// (kurallar ve fonksiyonlar `email_verified` bilgisini jetondan okur). Doğrulandıysa `true`.
  Future<bool> refreshEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final fresh = _auth.currentUser;
    if (fresh == null || !fresh.emailVerified) return false;
    await fresh.getIdToken(true);
    return true;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider)),
);

/// Oturum durumu: `null` = giriş yapılmamış.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
