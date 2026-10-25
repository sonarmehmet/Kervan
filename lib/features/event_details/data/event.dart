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
    );
  }

  bool get isCancelled => status == EventStatus.cancelled;
  bool get isFull => acceptedCount >= capacity;
  int get remainingSpots => math.max(0, capacity - acceptedCount);
  bool get hasStarted => !startsAt.isAfter(DateTime.now());

  /// Yeni katılım talebi alabilir mi?
  bool get isOpenForRequests => !isCancelled && !hasStarted;

  /// "Kadıköy, İstanbul" veya ilçe yoksa "İstanbul".
  String get locationLabel => district.isEmpty ? city : '$district, $city';
}
