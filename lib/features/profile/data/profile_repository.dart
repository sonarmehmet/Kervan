import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/services/firebase_providers.dart';
import '../../authentication/data/auth_repository.dart';
import 'user_profile.dart';

/// `users/{uid}` okuma/yazma. Kural doğrulaması firestore.rules içinde de yapılır.
class ProfileRepository {
  ProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.doc(FirestorePaths.user(uid));

  /// Belge yoksa `null` yayınlar (kullanıcı henüz profil oluşturmamış).
  Stream<UserProfile?> watchProfile(String uid) {
    return _doc(uid).snapshots().map(
          (snapshot) =>
              snapshot.exists ? UserProfile.fromFirestore(snapshot) : null,
        );
  }

  Future<UserProfile?> getProfile(String uid) async {
    final snapshot = await _doc(uid).get();
    return snapshot.exists ? UserProfile.fromFirestore(snapshot) : null;
  }

  Future<void> createProfile(String uid, ProfileInput input) {
    return _doc(uid).set(<String, dynamic>{
      'displayName': input.displayName.trim(),
      'bio': input.bio.trim(),
      'city': input.city,
      'interests': input.interests,
      'createdAt': FieldValue.serverTimestamp(),
      ..._accountFields(input),
    });
  }

  /// `createdAt` bilerek gönderilmez: kurallar değiştirilmesini yasaklar.
  Future<void> updateProfile(String uid, ProfileInput input) {
    return _doc(uid).update(<String, dynamic>{
      'displayName': input.displayName.trim(),
      'bio': input.bio.trim(),
      'city': input.city,
      'interests': input.interests,
      'updatedAt': FieldValue.serverTimestamp(),
      ..._accountFields(input),
    });
  }

  /// Bireyselde işletme adı silinir (kurallar business dışında izin vermez).
  Map<String, dynamic> _accountFields(ProfileInput input) {
    final business = input.accountType == AccountType.business;
    return <String, dynamic>{
      'accountType': input.accountType.value,
      'businessName':
          business ? input.businessName.trim() : FieldValue.delete(),
    };
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(firestoreProvider)),
);

/// Giriş yapmış kullanıcının profili. Giriş yoksa veya profil oluşturulmamışsa `null`.
final currentProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  // E-postası doğrulanmamış kullanıcı kurallar gereği veriye erişemez; profil yok sayılır.
  if (user == null || !user.emailVerified) return Stream<UserProfile?>.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(user.uid);
});
