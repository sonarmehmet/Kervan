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
  static const String terms = '/settings/terms';
  static const String verifyEmail = '/verify-email';

  // Etkinlikler. DİKKAT: 'create' sabit yolu ':eventId' değişkeninden ÖNCE tanımlanmalı.
  static const String createEvent = '/events/create';
  static String eventDetails(String eventId) => '/events/$eventId';
  static String editEvent(String eventId) => '/events/$eventId/edit';
  static String eventRequests(String eventId) => '/events/$eventId/requests';
  static String eventParticipants(String eventId) =>
      '/events/$eventId/participants';

  static String eventChat(String eventId) => '/events/$eventId/chat';

  // Gruplar ve takip. 'create' sabit yolu ':groupId' değişkeninden ÖNCE tanımlanmalı.
  static const String groups = '/groups';
  static const String createGroup = '/groups/create';
  static String groupDetails(String groupId) => '/groups/$groupId';
  static String editGroup(String groupId) => '/groups/$groupId/edit';
  static const String following = '/settings/following';
  static const String saved = '/saved';

  /// Giriş yapmadan erişilebilen yollar.
  static const Set<String> publicPaths = <String>{
    login,
    register,
    forgotPassword,
    privacyPolicy,
    terms,
  };
}
