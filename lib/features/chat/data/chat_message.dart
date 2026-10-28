import 'package:cloud_firestore/cloud_firestore.dart';

/// `events/{eventId}/messages/{messageId}`. Gönderen adı belgede yoktur.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;

  /// Sunucu zamanı henüz gelmediyse (yerel yazma) `null`.
  final DateTime? createdAt;

  factory ChatMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ChatMessage(
      id: doc.id,
      senderId: (data['senderId'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

abstract final class ChatLimits {
  static const int textMax = 500;
  static const int pageSize = 100;

  /// Null = geçerli. Boşluklar kırpılır.
  static String? validate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Mesaj boş olamaz.';
    if (text.length > textMax) return 'Mesaj en fazla $textMax karakter olabilir.';
    return null;
  }
}
