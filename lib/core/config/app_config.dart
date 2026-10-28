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

  /// Web için Firebase ayarları (Firebase konsolu > Proje ayarları > Web uygulaması).
  /// Kodda saklanmaz; `scripts/run_web.sh` --dart-define ile verir. Android/iOS'ta kullanılmaz.
  static const String webApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String webAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String webMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String webProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String webAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String webStorageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
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
