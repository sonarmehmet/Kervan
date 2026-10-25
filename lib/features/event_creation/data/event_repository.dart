import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/services/firebase_providers.dart';
import '../../event_details/data/event.dart';
import 'event_input.dart';

/// `events/{eventId}` ve `events/{eventId}/private/location` işlemleri.
class EventRepository {
  EventRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection(FirestorePaths.events);

  /// Etkinlik yoksa `null` yayınlar.
  Stream<Event?> watchEvent(String eventId) {
    return _events.doc(eventId).snapshots().map(
          (snapshot) => snapshot.exists ? Event.fromFirestore(snapshot) : null,
        );
  }

  /// Etkinlik ve tam adres TEK batch ile yazılır (kurallar buna göre yazıldı).
  /// Yeni etkinliğin kimliğini döner.
  Future<String> createEvent({
    required String ownerId,
    required String ownerName,
    required EventInput input,
  }) async {
    final ref = _events.doc();
    final batch = _firestore.batch();
    batch.set(ref, <String, dynamic>{
      'ownerId': ownerId,
      'ownerName': ownerName,
      'title': input.title.trim(),
      'description': input.description.trim(),
      'category': input.category,
      'city': input.city,
      'district': input.district.trim(),
      'startsAt': Timestamp.fromDate(input.startsAt),
      'capacity': input.capacity,
      'acceptedCount': 0,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _firestore.doc(FirestorePaths.eventLocation(ref.id)),
      <String, dynamic>{'address': input.address.trim()},
    );
    await batch.commit();
    return ref.id;
  }

  /// `acceptedCount`, `ownerId`, `status` ve `createdAt` gönderilmez:
  /// kurallar bunların istemciden değiştirilmesini yasaklar.
  Future<void> updateEvent(String eventId, EventInput input) async {
    final batch = _firestore.batch();
    batch.update(_events.doc(eventId), <String, dynamic>{
      'title': input.title.trim(),
      'description': input.description.trim(),
      'category': input.category,
      'city': input.city,
      'district': input.district.trim(),
      'startsAt': Timestamp.fromDate(input.startsAt),
      'capacity': input.capacity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _firestore.doc(FirestorePaths.eventLocation(eventId)),
      <String, dynamic>{'address': input.address.trim()},
    );
    await batch.commit();
  }

  /// İptal sunucuda yapılır: katılımcılara bildirim gider.
  Future<void> cancelEvent(String eventId) async {
    await _functions
        .httpsCallable(FunctionNames.cancelEvent)
        .call<void>(<String, dynamic>{'eventId': eventId});
  }

  /// Tam adres. Yalnızca sahip ve onaylı katılımcı okuyabilir; diğerleri için izin hatası verir.
  Future<String?> getAddress(String eventId) async {
    final snapshot =
        await _firestore.doc(FirestorePaths.eventLocation(eventId)).get();
    return snapshot.data()?['address'] as String?;
  }
}

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

/// Tek etkinlik (canlı). Etkinlik yoksa `null`.
final eventProvider = StreamProvider.family<Event?, String>(
  (ref, eventId) => ref.watch(eventRepositoryProvider).watchEvent(eventId),
);
