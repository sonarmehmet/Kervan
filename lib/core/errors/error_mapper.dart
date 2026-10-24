import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_exception.dart';

const String _genericMessage =
    'Beklenmeyen bir hata oluştu. Lütfen tekrar dene.';

/// Herhangi bir hatayı kullanıcıya gösterilecek Türkçe mesaja çevirir.
/// Hatayı yutmaz: çağıran taraf isterse ayrıca loglayabilir.
String mapErrorToMessage(Object error) {
  if (error is AppException) return error.message;
  if (error is FirebaseAuthException) return _authMessage(error.code);
  if (error is FirebaseFunctionsException) return _functionsMessage(error);
  if (error is FirebaseException) return _firebaseMessage(error.code);
  return _genericMessage;
}

String _authMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'E-posta adresi geçersiz.';
    case 'user-disabled':
      return 'Bu hesap devre dışı bırakılmış.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'E-posta veya şifre hatalı.';
    case 'email-already-in-use':
      return 'Bu e-posta adresiyle zaten bir hesap var.';
    case 'weak-password':
      return 'Şifre çok zayıf. Daha uzun ve karmaşık bir şifre seç.';
    case 'too-many-requests':
      return 'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.';
    case 'network-request-failed':
      return 'İnternet bağlantını kontrol et.';
    case 'requires-recent-login':
      return 'Bu işlem için yeniden giriş yapman gerekiyor.';
    case 'operation-not-allowed':
      return 'Bu giriş yöntemi şu an kapalı.';
    default:
      return 'Giriş işlemi başarısız oldu. Lütfen tekrar dene.';
  }
}

String _functionsMessage(FirebaseFunctionsException error) {
  // Sunucu tarafı (functions/) kullanıcıya gösterilecek mesajları Türkçe yazar.
  switch (error.code) {
    case 'failed-precondition':
    case 'invalid-argument':
    case 'not-found':
      final message = error.message;
      if (message != null && message.isNotEmpty) return message;
      return 'Bu işlem şu an yapılamıyor.';
    case 'permission-denied':
      return 'Bu işlem için yetkin yok.';
    case 'unauthenticated':
      return 'Devam etmek için giriş yapmalısın.';
    case 'unavailable':
    case 'deadline-exceeded':
      return 'Sunucuya ulaşılamıyor. İnternet bağlantını kontrol et.';
    default:
      return _genericMessage;
  }
}

String _firebaseMessage(String code) {
  switch (code) {
    case 'permission-denied':
      return 'Bu işlem için yetkin yok.';
    case 'unavailable':
    case 'deadline-exceeded':
      return 'Sunucuya ulaşılamıyor. İnternet bağlantını kontrol et.';
    case 'not-found':
      return 'Aradığın kayıt bulunamadı.';
    case 'resource-exhausted':
      return 'Şu an çok yoğunuz. Biraz sonra tekrar dene.';
    case 'unauthenticated':
      return 'Devam etmek için giriş yapmalısın.';
    default:
      return _genericMessage;
  }
}
