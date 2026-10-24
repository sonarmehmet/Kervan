/// Uygulamadaki tüm rota yolları. Elle string yazmak yerine bunları kullan.
abstract final class RoutePaths {
  // Oturum ve kurulum
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String profileSetup = '/profile-setup';

  // Alt gezinme sekmeleri
  static const String discover = '/discover';
  static const String myEvents = '/my-events';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  // Profil ve ayarlar
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String blockedUsers = '/settings/blocked';
  static const String privacyPolicy = '/settings/privacy';

  // Etkinlikler. DİKKAT: 'create' sabit yolu ':eventId' değişkeninden ÖNCE tanımlanmalı.
  static const String createEvent = '/events/create';
  static String eventDetails(String eventId) => '/events/$eventId';
  static String editEvent(String eventId) => '/events/$eventId/edit';
  static String eventRequests(String eventId) => '/events/$eventId/requests';
  static String eventParticipants(String eventId) =>
      '/events/$eventId/participants';

  /// Giriş yapmadan erişilebilen yollar.
  static const Set<String> publicPaths = <String>{
    login,
    register,
    forgotPassword,
    privacyPolicy,
  };
}
