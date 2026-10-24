import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/services/firebase_providers.dart';

/// Şikâyet edilen şeyin türü. `id` Firestore'a yazılır (firestore.rules: 'event' | 'user').
enum ReportTargetType {
  event('event'),
  user('user');

  const ReportTargetType(this.id);
  final String id;
}

/// Şikâyet nedenleri. `id` firestore.rules ile aynı olmalı.
enum ReportReason {
  spam('spam', 'Spam veya reklam'),
  harassment('harassment', 'Taciz veya saygısızlık'),
  unsafe('unsafe', 'Güvenli olmayan durum'),
  fake('fake', 'Sahte veya yanıltıcı'),
  other('other', 'Diğer');

  const ReportReason(this.id, this.label);
  final String id;
  final String label;
}

/// `reports/{reportId}` oluşturma. İstemci şikâyetleri okuyamaz (yalnızca yönetici).
class ReportRepository {
  ReportRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> submit({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String details = '',
  }) async {
    await _firestore.collection(FirestorePaths.reports).add(<String, dynamic>{
      'reporterId': reporterId,
      'targetType': targetType.id,
      'targetId': targetId,
      'reason': reason.id,
      'details': details.trim(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(firestoreProvider)),
);
