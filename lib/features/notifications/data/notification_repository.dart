import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/services/firebase_providers.dart';
import '../../authentication/data/auth_repository.dart';
import 'notification_item.dart';

class NotificationRepository {
  NotificationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _firestore.collection(FirestorePaths.userNotifications(uid));

  /// En yeni 50 bildirim.
  Stream<List<NotificationItem>> watchLatest(String uid) {
    return _items(uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(NotificationItem.fromFirestore).toList(),
        );
  }

  /// Kurallar yalnızca `read` alanının değişmesine izin verir.
  Future<void> markRead(String uid, String itemId) {
    return _items(uid).doc(itemId).update(<String, dynamic>{'read': true});
  }

  Future<void> markAllRead(String uid, List<NotificationItem> items) async {
    final unread = items.where((item) => !item.read).toList();
    if (unread.isEmpty) return;
    final batch = _firestore.batch();
    for (final item in unread) {
      batch.update(_items(uid).doc(item.id), <String, dynamic>{'read': true});
    }
    await batch.commit();
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(firestoreProvider)),
);

final notificationsProvider = StreamProvider<List<NotificationItem>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream<List<NotificationItem>>.value(const <NotificationItem>[]);
  }
  return ref.watch(notificationRepositoryProvider).watchLatest(user.uid);
});

/// Okunmamış bildirim sayısı (alt gezinmedeki rozet için).
final unreadNotificationCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return items.where((item) => !item.read).length;
});
