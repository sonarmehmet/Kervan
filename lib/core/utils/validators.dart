import '../config/app_config.dart';

/// Form doğrulayıcıları. Null dönerse alan geçerlidir.
/// Sınırlar firestore.rules ile uyumludur.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'E-posta adresini yaz.';
    if (!_emailPattern.hasMatch(text)) return 'Geçerli bir e-posta adresi yaz.';
    return null;
  }

  /// Kayıtta kullanılır: en az 8 karakter, en az bir harf ve bir rakam.
  /// (Girişte güç kuralı uygulanmaz; eski şifreler engellenmesin.)
  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Şifreni yaz.';
    if (text.length < AppConfig.passwordMin) {
      return 'Şifre en az ${AppConfig.passwordMin} karakter olmalı.';
    }
    if (text.length > 128) return 'Şifre en fazla 128 karakter olabilir.';
    final hasLetter = RegExp(r'\p{L}', unicode: true).hasMatch(text);
    final hasDigit = RegExp(r'\d').hasMatch(text);
    if (!hasLetter || !hasDigit) {
      return 'Şifre en az bir harf ve bir rakam içermeli.';
    }
    return null;
  }

  static String? displayName(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < AppConfig.displayNameMin) {
      return 'Adın en az ${AppConfig.displayNameMin} karakter olmalı.';
    }
    if (text.length > AppConfig.displayNameMax) {
      return 'Adın en fazla ${AppConfig.displayNameMax} karakter olabilir.';
    }
    return null;
  }

  static String? bio(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > AppConfig.bioMax) {
      return 'Hakkında yazısı en fazla ${AppConfig.bioMax} karakter olabilir.';
    }
    return null;
  }
}
