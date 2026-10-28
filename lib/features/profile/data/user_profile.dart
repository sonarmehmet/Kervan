import 'package:cloud_firestore/cloud_firestore.dart';

enum AccountType {
  individual('individual', 'Bireysel'),
  business('business', 'Kurumsal');

  const AccountType(this.value, this.label);

  final String value;
  final String label;

  static AccountType parse(String? value) =>
      value == 'business' ? AccountType.business : AccountType.individual;
}

/// `users/{uid}` belgesi. Şema: docs/firestore_schema.md
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    this.bio = '',
    this.city = '',
    this.interests = const <String>[],
    this.createdAt,
    this.accountType = AccountType.individual,
    this.businessName = '',
  });

  final String uid;
  final String displayName;
  final String bio;
  final String city;

  /// `EventCategory.id` değerleri.
  final List<String> interests;

  /// Sunucu zamanı henüz gelmediyse (yerel yazma) null olabilir.
  final DateTime? createdAt;

  /// Bireysel veya kurumsal hesap. Kurumsalda [businessName] herkese görünür.
  final AccountType accountType;
  final String businessName;

  bool get isBusiness => accountType == AccountType.business;

  /// Ekranlarda gösterilecek ad: kurumsalda işletme adı.
  String get publicName =>
      isBusiness && businessName.isNotEmpty ? businessName : displayName;

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
      accountType: AccountType.parse(data['accountType'] as String?),
      businessName: (data['businessName'] as String?) ?? '',
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
    this.accountType = AccountType.individual,
    this.businessName = '',
  });

  final String displayName;
  final String city;
  final String bio;
  final List<String> interests;
  final AccountType accountType;
  final String businessName;
}
