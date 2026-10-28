import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../authentication/data/auth_repository.dart';
import '../../event_creation/data/event_repository.dart';
import '../../moderation/data/block_repository.dart';
import '../../moderation/data/report_repository.dart';
import '../../moderation/presentation/block_user_dialog.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../../participation/data/participation_repository.dart';
import '../data/chat_message.dart';
import '../data/chat_repository.dart';

/// Etkinlik sohbeti. Yalnızca etkinlik sahibi ve onaylı katılımcılar erişebilir
/// (kural sunucuda zorunlu; erişim yoksa hata görünümü çıkar).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _send(String uid) async {
    final text = _controller.text;
    final error = ChatLimits.validate(text);
    if (error != null) {
      if (text.trim().isNotEmpty) _showMessage(error);
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(chatRepositoryProvider).send(
            eventId: widget.eventId,
            senderId: uid,
            text: text,
          );
      _controller.clear();
    } catch (e) {
      if (mounted) _showMessage(mapErrorToMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openActions({
    required ChatMessage message,
    required String senderName,
    required bool isMine,
    required bool isEventOwner,
  }) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMine || isEventOwner)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Mesajı sil'),
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
            if (!isMine)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Kullanıcıyı şikâyet et'),
                onTap: () => Navigator.pop(sheetContext, 'report'),
              ),
            if (!isMine)
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Kullanıcıyı engelle'),
                onTap: () => Navigator.pop(sheetContext, 'block'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'delete':
        try {
          await ref
              .read(chatRepositoryProvider)
              .delete(widget.eventId, message.id);
        } catch (e) {
          if (mounted) _showMessage(mapErrorToMessage(e));
        }
      case 'report':
        await showReportSheet(
          context,
          type: ReportTargetType.user,
          targetId: message.senderId,
        );
      case 'block':
        await confirmAndBlockUser(
          context,
          ref,
          userId: message.senderId,
          userName: senderName,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final event = ref.watch(eventProvider(widget.eventId)).valueOrNull;
    final participants =
        ref.watch(eventParticipantsProvider(widget.eventId)).valueOrNull ??
            const [];
    final blocked = ref.watch(blockedUserIdsProvider).valueOrNull ?? const {};
    final messagesAsync = ref.watch(chatMessagesProvider(widget.eventId));

    final names = <String, String>{
      for (final p in participants) p.userId: p.userName,
      if (event != null) event.ownerId: event.ownerName,
    };
    final isEventOwner = event != null && uid != null && event.ownerId == uid;
    final canWrite = uid != null && event != null && !event.isCancelled;

    Widget body;
    final messages = messagesAsync.valueOrNull;
    if (messages == null) {
      body = messagesAsync.hasError
          ? ErrorView(
              message: mapErrorToMessage(messagesAsync.error!),
              onRetry: () =>
                  ref.invalidate(chatMessagesProvider(widget.eventId)),
            )
          : const LoadingView();
    } else {
      final visible =
          messages.where((m) => !blocked.contains(m.senderId)).toList();
      body = visible.isEmpty
          ? const EmptyView(
              icon: Icons.chat_bubble_outline,
              title: 'Henüz mesaj yok',
              message: 'İlk mesajı sen yaz, buluşmayı planlayın.',
            )
          : ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final message = visible[index];
                final isMine = message.senderId == uid;
                final senderName = names[message.senderId] ?? 'Silinmiş kullanıcı';
                return _Bubble(
                  message: message,
                  senderName: senderName,
                  isMine: isMine,
                  onLongPress: () => _openActions(
                    message: message,
                    senderName: senderName,
                    isMine: isMine,
                    isEventOwner: isEventOwner,
                  ),
                );
              },
            );
    }

    return Scaffold(
      appBar: AppBar(title: Text(event?.title ?? 'Sohbet')),
      body: Column(
        children: [
          Expanded(child: body),
          if (event != null && event.isCancelled)
            Container(
              width: double.infinity,
              color: theme.colorScheme.errorContainer,
              padding: const EdgeInsets.all(12),
              child: Text(
                'Etkinlik iptal edildi; yeni mesaj gönderilemez.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          if (canWrite)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: ChatLimits.textMax,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Mesaj yaz...',
                          counterText: '',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Gönder',
                      onPressed: _sending ? null : () => _send(uid),
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.senderName,
    required this.isMine,
    required this.onLongPress,
  });

  final ChatMessage message;
  final String senderName;
  final bool isMine;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isMine
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = isMine
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final time = message.createdAt;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Card(
          color: background,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMine)
                    Text(
                      senderName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
                  ),
                  if (time != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        DateFormatters.eventDateTime(time),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: foreground.withAlpha(160),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
