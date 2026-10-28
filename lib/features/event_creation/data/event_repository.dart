import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/services/firebase_providers.dart';
import '../../event_details/data/event.dart';
import 'event_input.dart';
import 'recurrence.dart';

/// `events/{eventId}` ve `events/{eventId}/private/location` işlemleri.
class EventRepository {
  EventRepository(this._firestore, this._functions, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection(FirestorePaths.events);

  /// Etkinlik yoksa `null` yayınlar.
  Stream<Event?> watchEvent(String eventId) {
    return _events.doc(eventId).snapshots().map(
          (snapshot) => snapshot.exists ? Event.fromFirestore(snapshot) : null,
        );
  }

  /// Fotoğrafı `events/{ownerId}/{rastgele}.jpg` yoluna yükler ve indirme bağlantısını döner.
  /// Kurallar: yalnızca sahibi kendi klasörüne, en fazla 3 MB, görsel türünde yazabilir.
  Future<String> _uploadImage(String ownerId, Uint8List bytes) async {
    final name = _events.doc().id;
    final ref = _storage.ref('events/$ownerId/$name.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Eski fotoğrafı silmeyi dener; başarısız olursa sessizce geçer (yetim dosya zararsızdır).
  Future<void> _deleteImageQuietly(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {
      // Dosya zaten silinmiş veya erişilemiyor olabilir.
    }
  }

  Map<String, dynamic> _extraFields(EventInput input, String? imageUrl) {
    return <String, dynamic>{
      if (input.durationMinutes != null) 'durationMinutes': input.durationMinutes,
      if (input.costNote.trim().isNotEmpty) 'costNote': input.costNote.trim(),
      if (input.terms.trim().isNotEmpty) 'terms': input.terms.trim(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  /// Etkinlik(ler) ve tam adres(ler) TEK batch ile yazılır (kurallar buna göre yazıldı).
  /// Tekrar kuralı varsa seri oluşur (ortak `seriesId`, sıra `seriesIndex`); ilk etkinliğin
  /// kimliğini döner.
  Future<String> createEvent({
    required String ownerId,
    required String ownerName,
    required EventInput input,
  }) async {
    final imageUrl =
        input.newImage == null ? null : await _uploadImage(ownerId, input.newImage!);
    final dates = occurrenceDates(input.startsAt, input.recurrence, input.occurrences);
    final isSeries = dates.length > 1;
    final batch = _firestore.batch();
    String? firstId;
    String? seriesId;
    for (var i = 0; i < dates.length; i++) {
      final ref = _events.doc();
      firstId ??= ref.id;
      seriesId ??= ref.id;
      batch.set(ref, <String, dynamic>{
        'ownerId': ownerId,
        'ownerName': ownerName,
        'title': input.title.trim(),
        'description': input.description.trim(),
        'category': input.category,
        'city': input.city,
        'district': input.district.trim(),
        'startsAt': Timestamp.fromDate(dates[i]),
        'capacity': input.capacity,
        'acceptedCount': 0,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        ..._extraFields(input, imageUrl),
        if (isSeries) 'seriesId': seriesId,
        if (isSeries) 'seriesIndex': i,
        if (input.groupId != null && input.groupName != null) ...<String, dynamic>{
          'groupId': input.groupId,
          'groupName': input.groupName,
        },
      });
      batch.set(
        _firestore.doc(FirestorePaths.eventLocation(ref.id)),
        <String, dynamic>{'address': input.address.trim()},
      );
    }
    await batch.commit();
    return firstId!;
  }

  /// `acceptedCount`, `ownerId`, `status` ve `createdAt` gönderilmez:
  /// kurallar bunların istemciden değiştirilmesini yasaklar.
  Future<void> updateEvent(
    String eventId,
    EventInput input, {
    required String ownerId,
    String? previousImageUrl,
  }) async {
    final imageUrl = input.newImage != null
        ? await _uploadImage(ownerId, input.newImage!)
        : input.imageUrl;
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
      'durationMinutes': input.durationMinutes ?? FieldValue.delete(),
      'costNote': input.costNote.trim().isEmpty ? FieldValue.delete() : input.costNote.trim(),
      'terms': input.terms.trim().isEmpty ? FieldValue.delete() : input.terms.trim(),
      'imageUrl': imageUrl ?? FieldValue.delete(),
    });
    batch.set(
      _firestore.doc(FirestorePaths.eventLocation(eventId)),
      <String, dynamic>{'address': input.address.trim()},
    );
    await batch.commit();
    if (previousImageUrl != null && previousImageUrl != imageUrl) {
      await _deleteImageQuietly(previousImageUrl);
    }
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
    ref.watch(storageProvider),
  ),
);

/// Tek etkinlik (canlı). Etkinlik yoksa `null`.
final eventProvider = StreamProvider.family<Event?, String>(
  (ref, eventId) => ref.watch(eventRepositoryProvider).watchEvent(eventId),
);
