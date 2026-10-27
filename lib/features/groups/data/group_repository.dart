import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/services/firebase_providers.dart';
import '../../authentication/data/auth_repository.dart';
import '../../event_details/data/event.dart';
import 'group.dart';

/// Gruplar. Oluşturma/katılma/ayrılma Cloud Functions ile yapılır (üye sayısı tutarlılığı için);
/// sahip yalnızca bilgileri günceller ve grubu kapatır.
class GroupRepository {
  GroupRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection(FirestorePaths.groups);

  /// Aktif gruplar, en kalabalık önce.
  Stream<List<Group>> watchActiveGroups({int limit = 100}) {
    return _groups
        .where('status', isEqualTo: 'active')
        .orderBy('memberCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Group.fromFirestore).toList());
  }

  Stream<Group?> watchGroup(String groupId) {
    return _groups.doc(groupId).snapshots().map(
          (snap) => snap.exists ? Group.fromFirestore(snap) : null,
        );
  }

  Stream<bool> watchIsMember(String groupId, String uid) {
    return _firestore
        .doc(FirestorePaths.groupMember(groupId, uid))
        .snapshots()
        .map((snap) => snap.exists);
  }

  /// Sahibi olduğum aktif gruplar (etkinlik formunda grup seçimi için).
  Stream<List<Group>> watchOwned(String uid) {
    return _groups
        .where('ownerId', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) => snap.docs.map(Group.fromFirestore).toList());
  }

  /// Üye olduğum gruplar.
  Stream<List<Group>> watchMine(String uid) {
    return _firestore
        .collectionGroup(FirestorePaths.members)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .asyncMap((snap) async {
      final refs = snap.docs
          .map((doc) => doc.reference.parent.parent)
          .whereType<DocumentReference<Map<String, dynamic>>>();
      final docs = await Future.wait(refs.map((ref) => ref.get()));
      return docs
          .where((doc) => doc.exists)
          .map(Group.fromFirestore)
          .where((group) => !group.isClosed)
          .toList();
    });
  }

  /// Grubun yaklaşan aktif etkinlikleri.
  Stream<List<Event>> watchGroupEvents(String groupId) {
    return _firestore
        .collection(FirestorePaths.events)
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'active')
        .where('startsAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
        .orderBy('startsAt')
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(Event.fromFirestore).toList());
  }

  Future<String> create({
    required String name,
    required String description,
    required String category,
    required String city,
  }) async {
    final result = await _functions
        .httpsCallable(FunctionNames.createGroup)
        .call<Map<Object?, Object?>>(<String, dynamic>{
      'name': name.trim(),
      'description': description.trim(),
      'category': category,
      'city': city,
    });
    return result.data['groupId'] as String;
  }

  Future<void> join(String groupId) async {
    await _functions
        .httpsCallable(FunctionNames.joinGroup)
        .call<void>(<String, dynamic>{'groupId': groupId});
  }

  Future<void> leave(String groupId) async {
    await _functions
        .httpsCallable(FunctionNames.leaveGroup)
        .call<void>(<String, dynamic>{'groupId': groupId});
  }

  Future<void> update(
    String groupId, {
    required String name,
    required String description,
    required String category,
    required String city,
  }) {
    return _groups.doc(groupId).update(<String, dynamic>{
      'name': name.trim(),
      'description': description.trim(),
      'category': category,
      'city': city,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> close(String groupId) {
    return _groups.doc(groupId).update(<String, dynamic>{
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => GroupRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final activeGroupsProvider = StreamProvider<List<Group>>(
  (ref) => ref.watch(groupRepositoryProvider).watchActiveGroups(),
);

final groupProvider = StreamProvider.family<Group?, String>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).watchGroup(groupId),
);

final isGroupMemberProvider = StreamProvider.family<bool, String>((ref, groupId) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<bool>.value(false);
  return ref.watch(groupRepositoryProvider).watchIsMember(groupId, user.uid);
});

final ownedGroupsProvider = StreamProvider<List<Group>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<List<Group>>.value(const <Group>[]);
  return ref.watch(groupRepositoryProvider).watchOwned(user.uid);
});

final myGroupsProvider = StreamProvider<List<Group>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<List<Group>>.value(const <Group>[]);
  return ref.watch(groupRepositoryProvider).watchMine(user.uid);
});

final groupEventsProvider = StreamProvider.family<List<Event>, String>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).watchGroupEvents(groupId),
);
