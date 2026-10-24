/// Firestore koleksiyon ve belge yolları. Elle string yazmak yerine buradakileri kullan.
/// Şema: docs/firestore_schema.md
abstract final class FirestorePaths {
  static const String users = 'users';
  static const String blocks = 'blocks';
  static const String events = 'events';
  static const String privateDocs = 'private';
  static const String locationDocId = 'location';
  static const String requests = 'requests';
  static const String participants = 'participants';
  static const String notifications = 'notifications';
  static const String notificationItems = 'items';
  static const String reports = 'reports';

  static String user(String uid) => '$users/$uid';
  static String userBlocks(String uid) => '$users/$uid/$blocks';
  static String userBlock(String uid, String blockedUid) =>
      '$users/$uid/$blocks/$blockedUid';

  static String event(String eventId) => '$events/$eventId';
  static String eventLocation(String eventId) =>
      '$events/$eventId/$privateDocs/$locationDocId';
  static String eventRequests(String eventId) => '$events/$eventId/$requests';
  static String eventRequest(String eventId, String userId) =>
      '$events/$eventId/$requests/$userId';
  static String eventParticipants(String eventId) =>
      '$events/$eventId/$participants';
  static String eventParticipant(String eventId, String userId) =>
      '$events/$eventId/$participants/$userId';

  static String userNotifications(String uid) =>
      '$notifications/$uid/$notificationItems';
}
