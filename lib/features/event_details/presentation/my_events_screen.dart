import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../event_discovery/data/event_query_repository.dart';
import '../../event_discovery/presentation/event_card.dart';
import '../data/event.dart';

/// Etkinliklerim sekmesi: oluşturduklarım ve katıldıklarım.
class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Etkinliklerim'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Oluşturduklarım'),
              Tab(text: 'Katıldıklarım'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _EventList(
              source: _Source.owned,
              emptyTitle: 'Henüz etkinlik oluşturmadın',
              emptyMessage: 'Keşfet sekmesinden etkinlik oluşturabilirsin.',
            ),
            _EventList(
              source: _Source.joined,
              emptyTitle: 'Henüz katıldığın etkinlik yok',
              emptyMessage: 'Katılım talebin onaylanınca etkinlik burada görünür.',
            ),
          ],
        ),
      ),
    );
  }
}

enum _Source { owned, joined }

class _EventList extends ConsumerWidget {
  const _EventList({
    required this.source,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final _Source source;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = source == _Source.owned
        ? ownedEventsProvider
        : joinedEventsProvider;
    final async = ref.watch(provider);
    final events = async.valueOrNull;

    if (events == null) {
      if (async.hasError) {
        return ErrorView(
          message: mapErrorToMessage(async.error!),
          onRetry: () => ref.invalidate(provider),
        );
      }
      return const LoadingView();
    }
    if (events.isEmpty) {
      return EmptyView(
        icon: Icons.event_outlined,
        title: emptyTitle,
        message: emptyMessage,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final Event event = events[index];
        return EventCard(
          event: event,
          onTap: () => context.push(RoutePaths.eventDetails(event.id)),
        );
      },
    );
  }
}
