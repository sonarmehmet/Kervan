import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/firebase_providers.dart';
import 'chat_message.dart';

/// Etkinlik sohbeti. Yetki kontrolü firestore.rules'tadır (sahip ve onaylı katılımcılar).
class ChatRepository {
  ChatRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _messages(String eventId) =>
      _firestore.collection(FirestorePaths.eventMessages(eventId));

  /// En yeni mesajlar önce (en fazla [ChatLimits.pageSize]).
  Stream<List<ChatMessage>> watchMessages(String eventId) {
    return _messages(eventId)
        .orderBy('createdAt', descending: true)
        .limit(ChatLimits.pageSize)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());
  }

  Future<void> send({
    required String eventId,
    required String senderId,
    required String text,
  }) async {
    final error = ChatLimits.validate(text);
    if (error != null) throw AppException(error);
    await _messages(eventId).add(<String, dynamic>{
      'senderId': senderId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String eventId, String messageId) {
    return _messages(eventId).doc(messageId).delete();
  }
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(firestoreProvider)),
);

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>(
  (ref, eventId) => ref.watch(chatRepositoryProvider).watchMessages(eventId),
);
