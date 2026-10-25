import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../event_details/data/event.dart';
import '../../moderation/data/block_repository.dart';
import '../data/event_filter.dart';
import '../data/event_query_repository.dart';
import 'event_card.dart';
import 'filter_sheet.dart';

/// Keşfet sekmesi: gelecekteki aktif etkinlikler, filtreler, sayfalama.
class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(discoverFilterProvider);
    final limit = ref.watch(discoverLimitProvider);
    final eventsAsync = ref.watch(discoverEventsProvider);
    final blocked = ref.watch(blockedUserIdsProvider).valueOrNull ?? const <String>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşfet'),
        actions: [
          IconButton(
            tooltip: 'Filtrele',
            onPressed: () => showFilterSheet(context),
            icon: Badge(
              isLabelVisible: filter.isActive,
              label: Text('${filter.activeCount}'),
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.createEvent),
        icon: const Icon(Icons.add),
        label: const Text('Etkinlik oluştur'),
      ),
      body: _buildBody(context, ref, filter, limit, eventsAsync, blocked),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    EventFilter filter,
    int limit,
    AsyncValue<List<Event>> eventsAsync,
    Set<String> blocked,
  ) {
    final events = eventsAsync.valueOrNull;
    if (events == null) {
      if (eventsAsync.hasError) {
        return ErrorView(
          message: mapErrorToMessage(eventsAsync.error!),
          onRetry: () => ref.invalidate(discoverEventsProvider),
        );
      }
      return const LoadingView();
    }

    final visible = events.where((event) => !blocked.contains(event.ownerId)).toList();

    if (visible.isEmpty) {
      return filter.isActive
          ? EmptyView(
              icon: Icons.search_off,
              title: 'Filtrene uyan etkinlik yok',
              message: 'Filtreleri değiştirmeyi dene.',
              actionLabel: 'Filtreleri temizle',
              onAction: () {
                ref.read(discoverFilterProvider.notifier).state =
                    const EventFilter();
                ref.read(discoverLimitProvider.notifier).state =
                    discoverPageSize;
              },
            )
          : EmptyView(
              icon: Icons.explore_outlined,
              title: 'Henüz etkinlik yok',
              message: 'İlk etkinliği sen oluştur, diğerleri katılsın.',
              actionLabel: 'Etkinlik oluştur',
              onAction: () => context.push(RoutePaths.createEvent),
            );
    }

    final canLoadMore = events.length >= limit;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: visible.length + (canLoadMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visible.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton(
              onPressed: () => ref.read(discoverLimitProvider.notifier).state =
                  limit + discoverPageSize,
              child: const Text('Daha fazla göster'),
            ),
          );
        }
        final event = visible[index];
        return EventCard(
          event: event,
          onTap: () => context.push(RoutePaths.eventDetails(event.id)),
        );
      },
    );
  }
}
