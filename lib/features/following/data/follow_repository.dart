import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/firebase_providers.dart';
import '../../authentication/data/auth_repository.dart';

/// Takip edilen düzenleyen.
class Following {
  const Following({required this.organizerId, required this.organizerName});

  final String organizerId;
  final String organizerName;
}

/// Düzenleyen takibi: `users/{uid}/following/{organizerId}`. Yalnızca kendi listem görünür.
/// Takip edilen kişi etkinlik oluşturunca sunucu bildirim üretir.
class FollowRepository {
  FollowRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<Following>> watchFollowing(String uid) {
    return _firestore
        .collection(FirestorePaths.userFollowing(uid))
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => Following(
                  organizerId: doc.id,
                  organizerName: (doc.data()['organizerName'] as String?) ?? 'Kullanıcı',
                ),
              )
              .toList()
            ..sort((a, b) => a.organizerName.compareTo(b.organizerName)),
        );
  }

  Future<void> follow({
    required String uid,
    required String organizerId,
    required String organizerName,
  }) async {
    if (uid == organizerId) {
      throw const AppException('Kendini takip edemezsin.');
    }
    await _firestore.doc(FirestorePaths.userFollow(uid, organizerId)).set(
      <String, dynamic>{
        'organizerId': organizerId,
        'organizerName': organizerName,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> unfollow(String uid, String organizerId) {
    return _firestore.doc(FirestorePaths.userFollow(uid, organizerId)).delete();
  }
}

final followRepositoryProvider = Provider<FollowRepository>(
  (ref) => FollowRepository(ref.watch(firestoreProvider)),
);

final followingListProvider = StreamProvider<List<Following>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<List<Following>>.value(const <Following>[]);
  return ref.watch(followRepositoryProvider).watchFollowing(user.uid);
});

final isFollowingProvider = Provider.family<bool, String>((ref, organizerId) {
  final list = ref.watch(followingListProvider).valueOrNull ?? const <Following>[];
  return list.any((f) => f.organizerId == organizerId);
});
