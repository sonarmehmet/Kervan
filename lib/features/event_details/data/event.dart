import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

enum EventStatus {
  active('active'),
  cancelled('cancelled');

  const EventStatus(this.id);
  final String id;

  static EventStatus fromId(String? id) {
    for (final status in values) {
      if (status.id == id) return status;
    }
    return EventStatus.active;
  }
}

/// `events/{eventId}` belgesi. Şema: docs/firestore_schema.md
/// Tam adres bu belgede YOKTUR; `private/location` altında ayrı tutulur.
class Event {
  const Event({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.category,
    required this.city,
    required this.district,
    required this.startsAt,
    required this.capacity,
    required this.acceptedCount,
    required this.status,
    this.seriesId,
    this.groupId,
    this.groupName,
    this.imageUrl,
    this.durationMinutes,
    this.costNote = '',
    this.terms = '',
    this.saveCount = 0,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;

  /// `EventCategory.id`
  final String category;
  final String city;
  final String district;
  final DateTime startsAt;
  final int capacity;
  final int acceptedCount;
  final EventStatus status;

  /// Tekrarlayan etkinlik serisinin kimliği (yoksa `null`).
  final String? seriesId;

  /// Etkinliğin ait olduğu grup (yoksa `null`).
  final String? groupId;
  final String? groupName;

  /// Etkinlik fotoğrafı (Firebase Storage indirme bağlantısı); yoksa `null`.
  final String? imageUrl;

  /// Tahmini süre (dakika); belirtilmediyse `null`.
  final int? durationMinutes;

  /// "Hesap katılımcılara aittir", "Ücretsiz" gibi kısa not.
  final String costNote;

  /// Düzenleyenin katılım ve iptal koşulları.
  final String terms;

  /// Kaç kişi kaydetti (sunucu hesaplar).
  final int saveCount;

  /// Oluşturulma zamanı (sunucu zamanı; yazma anında henüz çözülmemiş olabilir).
  final DateTime? createdAt;

  factory Event.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Event(
      id: doc.id,
      ownerId: (data['ownerId'] as String?) ?? '',
      ownerName: (data['ownerName'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      category: (data['category'] as String?) ?? 'other',
      city: (data['city'] as String?) ?? '',
      district: (data['district'] as String?) ?? '',
      startsAt: (data['startsAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      acceptedCount: (data['acceptedCount'] as num?)?.toInt() ?? 0,
      status: EventStatus.fromId(data['status'] as String?),
      seriesId: data['seriesId'] as String?,
      groupId: data['groupId'] as String?,
      groupName: data['groupName'] as String?,
      imageUrl: data['imageUrl'] as String?,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt(),
      costNote: (data['costNote'] as String?) ?? '',
      terms: (data['terms'] as String?) ?? '',
      saveCount: (data['saveCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  DateTime? get endsAt => durationMinutes == null
      ? null
      : startsAt.add(Duration(minutes: durationMinutes!));

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get isCancelled => status == EventStatus.cancelled;
  bool get isFull => acceptedCount >= capacity;
  int get remainingSpots => math.max(0, capacity - acceptedCount);
  bool get hasStarted => !startsAt.isAfter(DateTime.now());

  /// Yeni katılım talebi alabilir mi?
  bool get isOpenForRequests => !isCancelled && !hasStarted;

  /// "Kadıköy, İstanbul" veya ilçe yoksa "İstanbul".
  String get locationLabel => district.isEmpty ? city : '$district, $city';
}
