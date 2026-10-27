import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../authentication/data/auth_repository.dart';
import '../../event_creation/data/event_repository.dart';
import '../../ratings/presentation/rating_widgets.dart';
import '../data/join_request.dart';
import '../data/participation_repository.dart';

/// Etkinlik sahibi için katılım talepleri: onayla / reddet.
class RequestListScreen extends ConsumerStatefulWidget {
  const RequestListScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends ConsumerState<RequestListScreen> {
  final Set<String> _busyUserIds = <String>{};

  Future<void> _decide(String userId, {required bool approve}) async {
    setState(() => _busyUserIds.add(userId));
    final repository = ref.read(participationRepositoryProvider);
    try {
      if (approve) {
        await repository.approve(eventId: widget.eventId, userId: userId);
      } else {
        await repository.reject(eventId: widget.eventId, userId: userId);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapErrorToMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _busyUserIds.remove(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventProvider(widget.eventId));
    final requestsAsync = ref.watch(eventRequestsProvider(widget.eventId));
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final theme = Theme.of(context);

    Widget body;
    final error = eventAsync.error ?? requestsAsync.error;
    final event = eventAsync.valueOrNull;
    final requests = requestsAsync.valueOrNull;

    if (error != null) {
      body = ErrorView(
        message: mapErrorToMessage(error),
        onRetry: () {
          ref.invalidate(eventProvider(widget.eventId));
          ref.invalidate(eventRequestsProvider(widget.eventId));
        },
      );
    } else if (event == null || requests == null) {
      body = eventAsync.isLoading || requestsAsync.isLoading
          ? const LoadingView()
          : const EmptyView(icon: Icons.event_busy, title: 'Etkinlik bulunamadı');
    } else if (event.ownerId != uid) {
      body = const EmptyView(
        icon: Icons.lock_outline,
        title: 'Bu sayfayı görme yetkin yok',
      );
    } else {
      final pending =
          requests.where((r) => r.status == RequestStatus.pending).toList();
      final decided = requests
          .where((r) =>
              r.status == RequestStatus.approved ||
              r.status == RequestStatus.rejected)
          .toList();

      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups),
              title: Text(event.title),
              subtitle: Text(
                '${event.acceptedCount}/${event.capacity} kişi onaylandı',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Bekleyen talepler', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (pending.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Bekleyen talep yok.')),
            ),
          for (final request in pending)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(request.userName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RatingBadge(userId: request.userId, asOrganizer: false),
                    if (request.createdAt != null)
                      Text(DateFormatters.eventDateTime(request.createdAt!)),
                  ],
                ),
                trailing: _busyUserIds.contains(request.userId)
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: event.isFull
                                ? 'Kapasite dolu'
                                : 'Onayla',
                            icon: const Icon(Icons.check_circle_outline),
                            color: theme.colorScheme.primary,
                            onPressed: event.isFull || event.isCancelled
                                ? null
                                : () => _decide(request.userId, approve: true),
                          ),
                          IconButton(
                            tooltip: 'Reddet',
                            icon: const Icon(Icons.cancel_outlined),
                            color: theme.colorScheme.error,
                            onPressed: () =>
                                _decide(request.userId, approve: false),
                          ),
                        ],
                      ),
              ),
            ),
          if (decided.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Önceki kararlar', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final request in decided)
              ListTile(
                leading: Icon(
                  request.status == RequestStatus.approved
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: request.status == RequestStatus.approved
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                title: Text(request.userName),
                subtitle: Text(
                  request.status == RequestStatus.approved
                      ? 'Onaylandı'
                      : 'Reddedildi',
                ),
              ),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Katılım talepleri')),
      body: body,
    );
  }
}
