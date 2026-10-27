/// Uygulama genelinde kullanılan sabit ayarlar.
abstract final class AppConfig {
  static const String appName = 'Rota';

  /// Cloud Functions bölgesi. `functions/` tarafındaki bölgeyle aynı olmalı.
  static const String functionsRegion = 'europe-west1';

  // Profil sınırları (firestore.rules ile aynı olmalı).
  static const int displayNameMin = 2;
  static const int displayNameMax = 40;
  static const int bioMax = 280;
  static const int maxInterests = 10;

  static const int passwordMin = 8;

  /// Paylaşım bağlantılarının tabanı (ör. https://rota-app.web.app). Derlemede verilir:
  ///   flutter run --dart-define=SHARE_BASE_URL=https://PROJE.web.app
  /// Boşsa paylaşım metni bağlantısız gider.
  static const String shareBaseUrl = String.fromEnvironment('SHARE_BASE_URL');
}

/// Çağrılabilir (callable) Cloud Function adları.
/// Sözleşme: docs/firestore_schema.md
abstract final class FunctionNames {
  static const String approveRequest = 'approveRequest';
  static const String rejectRequest = 'rejectRequest';
  static const String leaveEvent = 'leaveEvent';
  static const String cancelEvent = 'cancelEvent';
  static const String deleteAccount = 'deleteAccount';
  static const String joinWaitlist = 'joinWaitlist';
  static const String leaveWaitlist = 'leaveWaitlist';
  static const String submitRating = 'submitRating';
  static const String createGroup = 'createGroup';
  static const String joinGroup = 'joinGroup';
  static const String leaveGroup = 'leaveGroup';
}
