import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/firebase_providers.dart';
import '../../authentication/data/auth_repository.dart';
import 'join_request.dart';

/// Katılım talebi ve katılımcı işlemleri.
/// Onay, red ve ayrılma Cloud Functions ile yapılır (kapasite güvenliği için).
class ParticipationRepository {
  ParticipationRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  DocumentReference<Map<String, dynamic>> _request(String eventId, String uid) =>
      _firestore.doc(FirestorePaths.eventRequest(eventId, uid));

  /// Kullanıcının bu etkinlik için talebi. Yoksa `null`.
  Stream<JoinRequest?> watchRequest(String eventId, String uid) {
    return _request(eventId, uid).snapshots().map(
          (snapshot) =>
              snapshot.exists ? JoinRequest.fromFirestore(snapshot) : null,
        );
  }

  /// Kullanıcı onaylı katılımcı mı?
  Stream<bool> watchIsParticipant(String eventId, String uid) {
    return _firestore
        .doc(FirestorePaths.eventParticipant(eventId, uid))
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  /// Etkinliğin tüm talepleri (yalnızca sahip okuyabilir). Süzme istemcide yapılır:
  /// durum + sıralama birleşik index gerektirirdi.
  Stream<List<JoinRequest>> watchRequests(String eventId) {
    return _firestore
        .collection(FirestorePaths.eventRequests(eventId))
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(JoinRequest.fromFirestore).toList(),
        );
  }

  Stream<List<Participant>> watchParticipants(String eventId) {
    return _firestore
        .collection(FirestorePaths.eventParticipants(eventId))
        .orderBy('joinedAt')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(Participant.fromFirestore).toList(),
        );
  }

  /// Yeni talep gönderir. Daha önce geri çekilmiş (`cancelled`) talep yeniden açılır.
  /// Reddedilmiş talep tekrar gönderilemez (kurallar da engeller).
  Future<void> sendRequest({
    required String eventId,
    required String uid,
    required String userName,
  }) async {
    final ref = _request(eventId, uid);
    final existing = await ref.get();
    if (existing.exists) {
      final status = existing.data()?['status'];
      if (status == RequestStatus.cancelled.id) {
        await ref.update(<String, dynamic>{'status': RequestStatus.pending.id});
        return;
      }
      throw const AppException('Bu etkinlik için zaten bir talebin var.');
    }
    await ref.set(<String, dynamic>{
      'userId': uid,
      'userName': userName,
      'status': RequestStatus.pending.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Bekleyen talebi geri çeker.
  Future<void> cancelRequest({required String eventId, required String uid}) {
    return _request(eventId, uid).update(
      <String, dynamic>{'status': RequestStatus.cancelled.id},
    );
  }

  Future<void> approve({required String eventId, required String userId}) =>
      _call(FunctionNames.approveRequest, <String, dynamic>{
        'eventId': eventId,
        'userId': userId,
      });

  Future<void> reject({required String eventId, required String userId}) =>
      _call(FunctionNames.rejectRequest, <String, dynamic>{
        'eventId': eventId,
        'userId': userId,
      });

  Future<void> leave({required String eventId}) =>
      _call(FunctionNames.leaveEvent, <String, dynamic>{'eventId': eventId});

  Future<void> _call(String name, Map<String, dynamic> data) async {
    await _functions.httpsCallable(name).call<void>(data);
  }
}

final participationRepositoryProvider = Provider<ParticipationRepository>(
  (ref) => ParticipationRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

/// Giriş yapmış kullanıcının bu etkinlik için talebi.
final myRequestProvider = StreamProvider.family<JoinRequest?, String>(
  (ref, eventId) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return Stream<JoinRequest?>.value(null);
    return ref
        .watch(participationRepositoryProvider)
        .watchRequest(eventId, user.uid);
  },
);

/// Giriş yapmış kullanıcı bu etkinliğin onaylı katılımcısı mı?
final isParticipantProvider = StreamProvider.family<bool, String>(
  (ref, eventId) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return Stream<bool>.value(false);
    return ref
        .watch(participationRepositoryProvider)
        .watchIsParticipant(eventId, user.uid);
  },
);

/// Etkinliğin talepleri. Yalnızca etkinlik sahibi için kullan (başkası için izin hatası verir).
final eventRequestsProvider = StreamProvider.family<List<JoinRequest>, String>(
  (ref, eventId) =>
      ref.watch(participationRepositoryProvider).watchRequests(eventId),
);

/// Etkinliğin katılımcıları. Sahip ve katılımcılar için.
final eventParticipantsProvider = StreamProvider.family<List<Participant>, String>(
  (ref, eventId) =>
      ref.watch(participationRepositoryProvider).watchParticipants(eventId),
);
