import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/event_categories.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/text_search.dart';
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
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Başlık, açıklama, kategori (ve grubu), şehir, ilçe ve düzenleyen adında arar.
  bool _matchesQuery(Event event) {
    if (_query.trim().isEmpty) return true;
    final category = EventCategory.byId(event.category);
    return matchesSearch(_query, [
      event.title,
      event.description,
      category.label,
      category.group.label,
      event.city,
      event.district,
      event.ownerName,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final filter = ref.watch(discoverFilterProvider);
    final limit = ref.watch(discoverLimitProvider);
    final eventsAsync = ref.watch(discoverEventsProvider);
    final blocked = ref.watch(blockedUserIdsProvider).valueOrNull ?? const <String>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşfet'),
        actions: [
          IconButton(
            tooltip: 'Gruplar',
            onPressed: () => context.push(RoutePaths.groups),
            icon: const Icon(Icons.groups_outlined),
          ),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Etkinlik, kategori veya şehir ara',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll<double>(0),
              onChanged: (value) => setState(() => _query = value),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    tooltip: 'Aramayı temizle',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(context, ref, filter, limit, eventsAsync, blocked),
          ),
        ],
      ),
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

    final visible = events
        .where((event) => !blocked.contains(event.ownerId))
        .where(_matchesQuery)
        .toList();

    if (visible.isEmpty && _query.trim().isNotEmpty) {
      return EmptyView(
        icon: Icons.search_off,
        title: 'Sonuç bulunamadı',
        message:
            '"${_query.trim()}" için yüklenen etkinliklerde eşleşme yok. Farklı bir sözcük dene'
            '${events.length >= limit ? ' veya daha fazla etkinlik yükle' : ''}.',
        actionLabel: events.length >= limit ? 'Daha fazla yükle' : null,
        onAction: events.length >= limit
            ? () => ref.read(discoverLimitProvider.notifier).state =
                limit + discoverPageSize
            : null,
      );
    }

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
