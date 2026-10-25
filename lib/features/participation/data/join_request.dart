import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  cancelled('cancelled');

  const RequestStatus(this.id);
  final String id;

  static RequestStatus fromId(String? id) {
    for (final status in values) {
      if (status.id == id) return status;
    }
    return RequestStatus.pending;
  }
}

/// `events/{eventId}/requests/{userId}`
class JoinRequest {
  const JoinRequest({
    required this.userId,
    required this.userName,
    required this.status,
    this.createdAt,
  });

  final String userId;
  final String userName;
  final RequestStatus status;
  final DateTime? createdAt;

  factory JoinRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return JoinRequest(
      userId: (data['userId'] as String?) ?? doc.id,
      userName: (data['userName'] as String?) ?? '',
      status: RequestStatus.fromId(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// `events/{eventId}/participants/{userId}` (yalnızca Cloud Functions yazar)
class Participant {
  const Participant({
    required this.userId,
    required this.userName,
    this.joinedAt,
  });

  final String userId;
  final String userName;
  final DateTime? joinedAt;

  factory Participant.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Participant(
      userId: (data['userId'] as String?) ?? doc.id,
      userName: (data['userName'] as String?) ?? '',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
    );
  }
}
