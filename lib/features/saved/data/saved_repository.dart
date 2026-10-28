import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/services/firebase_providers.dart';
import '../../authentication/data/auth_repository.dart';
import '../../event_details/data/event.dart';

/// Kaydettiğim etkinlikler: `users/{uid}/saved/{eventId}`. Yalnızca kendi listem görünür;
/// etkinliğin `saveCount` değerini sunucu hesaplar.
class SavedRepository {
  SavedRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<Set<String>> watchSavedIds(String uid) {
    return _firestore
        .collection(FirestorePaths.userSaved(uid))
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toSet());
  }

  Future<void> save(String uid, String eventId) {
    return _firestore.doc(FirestorePaths.userSavedItem(uid, eventId)).set(
      <String, dynamic>{
        'eventId': eventId,
        'savedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> unsave(String uid, String eventId) {
    return _firestore.doc(FirestorePaths.userSavedItem(uid, eventId)).delete();
  }

  /// Kaydedilen etkinlikleri getirir: yaklaşanlar önce (tarihe göre), geçmişler sonda.
  Stream<List<Event>> watchSavedEvents(String uid) {
    return watchSavedIds(uid).asyncMap((ids) async {
      final list = ids.toList();
      final events = <Event>[];
      for (var i = 0; i < list.length; i += 10) {
        final chunk = list.sublist(i, i + 10 > list.length ? list.length : i + 10);
        final snap = await _firestore
            .collection(FirestorePaths.events)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        events.addAll(snap.docs.map(Event.fromFirestore));
      }
      return sortSavedEvents(events, DateTime.now());
    });
  }
}

/// Yaklaşan etkinlikler tarihe göre artan, geçmiş olanlar sonda (en yeni önce).
List<Event> sortSavedEvents(List<Event> events, DateTime now) {
  final upcoming = events.where((e) => e.startsAt.isAfter(now)).toList()
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  final past = events.where((e) => !e.startsAt.isAfter(now)).toList()
    ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
  return <Event>[...upcoming, ...past];
}

final savedRepositoryProvider = Provider<SavedRepository>(
  (ref) => SavedRepository(ref.watch(firestoreProvider)),
);

final savedIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<Set<String>>.value(const <String>{});
  return ref.watch(savedRepositoryProvider).watchSavedIds(user.uid);
});

final isSavedProvider = Provider.family<bool, String>((ref, eventId) {
  return ref.watch(savedIdsProvider).valueOrNull?.contains(eventId) ?? false;
});

final savedEventsProvider = StreamProvider<List<Event>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<List<Event>>.value(const <Event>[]);
  return ref.watch(savedRepositoryProvider).watchSavedEvents(user.uid);
});
