import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  requestReceived('request_received'),
  requestApproved('request_approved'),
  requestRejected('request_rejected'),
  eventCancelled('event_cancelled'),
  waitlistSpotOpen('waitlist_spot_open'),
  eventReminder24h('event_reminder_24h'),
  eventReminder1h('event_reminder_1h'),
  newFollowedEvent('new_followed_event'),
  newGroupEvent('new_group_event'),
  unknown('unknown');

  const NotificationType(this.id);
  final String id;

  static NotificationType fromId(String? id) {
    for (final type in values) {
      if (type.id == id) return type;
    }
    return NotificationType.unknown;
  }
}

/// `notifications/{uid}/items/{itemId}` (yalnızca Cloud Functions oluşturur)
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.eventId,
    required this.eventTitle,
    required this.read,
    this.createdAt,
    this.actorName = '',
    this.groupName = '',
  });

  final String id;
  final NotificationType type;
  final String eventId;
  final String eventTitle;
  final bool read;
  final DateTime? createdAt;

  /// `new_followed_event`: düzenleyenin adı.
  final String actorName;

  /// `new_group_event`: grubun adı.
  final String groupName;

  factory NotificationItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return NotificationItem(
      id: doc.id,
      type: NotificationType.fromId(data['type'] as String?),
      eventId: (data['eventId'] as String?) ?? '',
      eventTitle: (data['eventTitle'] as String?) ?? '',
      read: (data['read'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      actorName: (data['actorName'] as String?) ?? '',
      groupName: (data['groupName'] as String?) ?? '',
    );
  }

  /// Kullanıcıya gösterilen Türkçe metin.
  String get message {
    switch (type) {
      case NotificationType.requestReceived:
        return '"$eventTitle" etkinliğine yeni bir katılım talebi geldi.';
      case NotificationType.requestApproved:
        return '"$eventTitle" etkinliğine katılım talebin onaylandı.';
      case NotificationType.requestRejected:
        return '"$eventTitle" etkinliğine katılım talebin reddedildi.';
      case NotificationType.eventCancelled:
        return '"$eventTitle" etkinliği iptal edildi.';
      case NotificationType.waitlistSpotOpen:
        return '"$eventTitle" etkinliğinde yer açıldı. Hemen katılma isteği gönder.';
      case NotificationType.eventReminder24h:
        return '"$eventTitle" etkinliği 24 saat içinde başlıyor.';
      case NotificationType.eventReminder1h:
        return '"$eventTitle" etkinliği 1 saat içinde başlıyor.';
      case NotificationType.newFollowedEvent:
        final who = actorName.isEmpty ? 'Takip ettiğin düzenleyen' : actorName;
        return '$who yeni bir etkinlik oluşturdu: "$eventTitle"';
      case NotificationType.newGroupEvent:
        final group = groupName.isEmpty ? 'Grubun' : groupName;
        return '$group için yeni etkinlik: "$eventTitle"';
      case NotificationType.unknown:
        return '"$eventTitle" etkinliğiyle ilgili bir güncelleme var.';
    }
  }
}
