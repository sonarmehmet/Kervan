import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/notification_item.dart';
import '../data/notification_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid != null && !item.read) {
      try {
        await ref.read(notificationRepositoryProvider).markRead(uid, item.id);
      } catch (_) {
        // Okundu işareti başarısız olsa da etkinliğe gitmeye devam et.
      }
    }
    if (!context.mounted || item.eventId.isEmpty) return;
    await context.push(RoutePaths.eventDetails(item.eventId));
  }

  Future<void> _markAllRead(
    BuildContext context,
    WidgetRef ref,
    List<NotificationItem> items,
  ) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;
    try {
      await ref.read(notificationRepositoryProvider).markAllRead(uid, items);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapErrorToMessage(error))),
      );
    }
  }

  static IconData _icon(NotificationType type) {
    switch (type) {
      case NotificationType.requestReceived:
        return Icons.person_add_alt_1;
      case NotificationType.requestApproved:
        return Icons.check_circle;
      case NotificationType.requestRejected:
        return Icons.cancel;
      case NotificationType.eventCancelled:
        return Icons.event_busy;
      case NotificationType.unknown:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final items = async.valueOrNull;
    final theme = Theme.of(context);
    final hasUnread = items != null && items.any((item) => !item.read);

    Widget body;
    if (items == null) {
      body = async.hasError
          ? ErrorView(
              message: mapErrorToMessage(async.error!),
              onRetry: () => ref.invalidate(notificationsProvider),
            )
          : const LoadingView();
    } else if (items.isEmpty) {
      body = const EmptyView(
        icon: Icons.notifications_none,
        title: 'Bildirimin yok',
        message: 'Katılım talepleri ve etkinlik güncellemeleri burada görünür.',
      );
    } else {
      body = ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            tileColor: item.read
                ? null
                : theme.colorScheme.primaryContainer.withAlpha(60),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(
                _icon(item.type),
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            title: Text(
              item.message,
              style: TextStyle(
                fontWeight: item.read ? FontWeight.normal : FontWeight.w600,
              ),
            ),
            subtitle: item.createdAt == null
                ? null
                : Text(DateFormatters.eventDateTime(item.createdAt!)),
            onTap: () => _open(context, ref, item),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () => _markAllRead(context, ref, items),
              child: const Text('Tümünü okundu yap'),
            ),
        ],
      ),
      body: body,
    );
  }
}
