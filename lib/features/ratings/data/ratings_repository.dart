import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/firebase_providers.dart';
import '../../authentication/data/auth_repository.dart';
import 'user_stats.dart';

/// Anonim, karşılıklı değerlendirme. Yazma Cloud Function ile yapılır.
class RatingsRepository {
  RatingsRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Future<void> submit({
    required String eventId,
    required String targetUserId,
    required int stars,
  }) async {
    if (stars < 1 || stars > 5) {
      throw const AppException('Puan 1 ile 5 arasında olmalı.');
    }
    await _functions.httpsCallable(FunctionNames.submitRating).call<void>(
      <String, dynamic>{
        'eventId': eventId,
        'targetUserId': targetUserId,
        'stars': stars,
      },
    );
  }

  /// Bu etkinlikte BENİM puanladığım kişilerin uid'leri (yalnızca kendi kayıtlarım okunur).
  Stream<Set<String>> watchMyRatedTargets(String eventId, String uid) {
    return _firestore
        .collection(FirestorePaths.ratings)
        .where('eventId', isEqualTo: eventId)
        .where('raterId', isEqualTo: uid)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => (doc.data()['targetId'] as String?) ?? '')
              .where((id) => id.isNotEmpty)
              .toSet(),
        );
  }

  Stream<UserStats> watchStats(String uid) {
    return _firestore
        .doc(FirestorePaths.userStat(uid))
        .snapshots()
        .map(UserStats.fromFirestore);
  }
}

final ratingsRepositoryProvider = Provider<RatingsRepository>(
  (ref) => RatingsRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final userStatsProvider = StreamProvider.family<UserStats, String>(
  (ref, uid) => ref.watch(ratingsRepositoryProvider).watchStats(uid),
);

final myRatedTargetsProvider = StreamProvider.family<Set<String>, String>(
  (ref, eventId) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return Stream<Set<String>>.value(const <String>{});
    return ref
        .watch(ratingsRepositoryProvider)
        .watchMyRatedTargets(eventId, user.uid);
  },
);
