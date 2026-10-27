import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupStatus {
  active('active'),
  closed('closed');

  const GroupStatus(this.id);
  final String id;

  static GroupStatus fromId(String? id) =>
      id == 'closed' ? GroupStatus.closed : GroupStatus.active;
}

/// `groups/{groupId}`. Şema: docs/firestore_schema.md
class Group {
  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.city,
    required this.ownerId,
    required this.ownerName,
    required this.memberCount,
    required this.status,
  });

  final String id;
  final String name;
  final String description;

  /// `EventCategory.id`
  final String category;
  final String city;
  final String ownerId;
  final String ownerName;
  final int memberCount;
  final GroupStatus status;

  bool get isClosed => status == GroupStatus.closed;

  factory Group.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Group(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      category: (data['category'] as String?) ?? 'other',
      city: (data['city'] as String?) ?? '',
      ownerId: (data['ownerId'] as String?) ?? '',
      ownerName: (data['ownerName'] as String?) ?? '',
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      status: GroupStatus.fromId(data['status'] as String?),
    );
  }
}

abstract final class GroupLimits {
  static const int nameMin = 3;
  static const int nameMax = 50;
  static const int descriptionMax = 500;

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < nameMin) return 'Grup adı en az $nameMin karakter olmalı.';
    if (text.length > nameMax) return 'Grup adı en fazla $nameMax karakter olabilir.';
    return null;
  }

  static String? description(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > descriptionMax) {
      return 'Açıklama en fazla $descriptionMax karakter olabilir.';
    }
    return null;
  }
}
