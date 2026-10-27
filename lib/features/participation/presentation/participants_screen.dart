import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../event_creation/data/event_repository.dart';
import '../../ratings/presentation/rating_widgets.dart';
import '../data/participation_repository.dart';

/// Onaylı katılımcı listesi (etkinlik sahibi ve katılımcılar görür).
class ParticipantsScreen extends ConsumerWidget {
  const ParticipantsScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventProvider(eventId));
    final participantsAsync = ref.watch(eventParticipantsProvider(eventId));
    final theme = Theme.of(context);

    Widget body;
    final error = eventAsync.error ?? participantsAsync.error;
    final event = eventAsync.valueOrNull;
    final participants = participantsAsync.valueOrNull;

    if (error != null) {
      body = ErrorView(
        message: mapErrorToMessage(error),
        onRetry: () {
          ref.invalidate(eventProvider(eventId));
          ref.invalidate(eventParticipantsProvider(eventId));
        },
      );
    } else if (event == null || participants == null) {
      body = eventAsync.isLoading || participantsAsync.isLoading
          ? const LoadingView()
          : const EmptyView(icon: Icons.event_busy, title: 'Etkinlik bulunamadı');
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${event.acceptedCount}/${event.capacity} kişi',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.star,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(event.ownerName),
              subtitle: const Text('Düzenleyen'),
            ),
          ),
          if (participants.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Henüz onaylanmış katılımcı yok.')),
            ),
          for (final participant in participants)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(participant.userName),
                subtitle: RatingBadge(userId: participant.userId, asOrganizer: false),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Katılımcılar')),
      body: body,
    );
  }
}
