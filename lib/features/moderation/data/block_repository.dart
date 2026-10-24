import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/firebase_providers.dart';
import '../../authentication/data/auth_repository.dart';

/// `users/{uid}/blocks/{blockedUid}` işlemleri.
class BlockRepository {
  BlockRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _blocks(String uid) =>
      _firestore.collection(FirestorePaths.userBlocks(uid));

  /// Engellenen kullanıcıların uid listesi (canlı).
  Stream<Set<String>> watchBlockedIds(String uid) {
    return _blocks(uid).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.id).toSet(),
        );
  }

  Future<void> block({required String uid, required String blockedUid}) {
    if (uid == blockedUid) {
      throw const AppException('Kendini engelleyemezsin.');
    }
    return _blocks(uid).doc(blockedUid).set(<String, dynamic>{
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblock({required String uid, required String blockedUid}) {
    return _blocks(uid).doc(blockedUid).delete();
  }
}

final blockRepositoryProvider = Provider<BlockRepository>(
  (ref) => BlockRepository(ref.watch(firestoreProvider)),
);

/// Giriş yapmış kullanıcının engellediği kişilerin uid'leri.
/// B (keşif ve detay) etkinlikleri bu kümeye göre istemcide süzer:
/// `ref.watch(blockedUserIdsProvider).valueOrNull ?? const {}`
final blockedUserIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<Set<String>>.value(const <String>{});
  return ref.watch(blockRepositoryProvider).watchBlockedIds(user.uid);
});
