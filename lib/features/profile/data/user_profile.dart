import 'package:cloud_firestore/cloud_firestore.dart';

/// `users/{uid}` belgesi. Şema: docs/firestore_schema.md
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    this.bio = '',
    this.city = '',
    this.interests = const <String>[],
    this.createdAt,
  });

  final String uid;
  final String displayName;
  final String bio;
  final String city;

  /// `EventCategory.id` değerleri.
  final List<String> interests;

  /// Sunucu zamanı henüz gelmediyse (yerel yazma) null olabilir.
  final DateTime? createdAt;

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return UserProfile(
      uid: doc.id,
      displayName: (data['displayName'] as String?) ?? '',
      bio: (data['bio'] as String?) ?? '',
      city: (data['city'] as String?) ?? '',
      interests: List<String>.from(
        (data['interests'] as List<dynamic>?) ?? const <String>[],
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Profil formundan gelen değerler (oluşturma ve düzenleme için ortak).
class ProfileInput {
  const ProfileInput({
    required this.displayName,
    required this.city,
    required this.bio,
    required this.interests,
  });

  final String displayName;
  final String city;
  final String bio;
  final List<String> interests;
}
