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
  static const String messages = 'messages';
  static const String waitlist = 'waitlist';
  static const String following = 'following';
  static const String groups = 'groups';
  static const String members = 'members';
  static const String ratings = 'ratings';
  static const String userStats = 'userStats';
  static const String notifications = 'notifications';
  static const String notificationItems = 'items';
  static const String reports = 'reports';

  static String user(String uid) => '$users/$uid';
  static String userBlocks(String uid) => '$users/$uid/$blocks';
  static String userBlock(String uid, String blockedUid) =>
      '$users/$uid/$blocks/$blockedUid';

  static const String fcmTokens = 'fcmTokens';
  static String userFcmToken(String uid, String token) =>
      '$users/$uid/$fcmTokens/$token';

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

  static String eventMessages(String eventId) => '$events/$eventId/$messages';

  static String eventWaitlist(String eventId) => '$events/$eventId/$waitlist';
  static String eventWaitlistEntry(String eventId, String userId) =>
      '$events/$eventId/$waitlist/$userId';
  static String userFollowing(String uid) => '$users/$uid/$following';
  static String userFollow(String uid, String organizerId) =>
      '$users/$uid/$following/$organizerId';
  static String group(String groupId) => '$groups/$groupId';
  static String groupMembers(String groupId) => '$groups/$groupId/$members';
  static String groupMember(String groupId, String uid) =>
      '$groups/$groupId/$members/$uid';
  static String userStat(String uid) => '$userStats/$uid';

  static String userNotifications(String uid) =>
      '$notifications/$uid/$notificationItems';
}
