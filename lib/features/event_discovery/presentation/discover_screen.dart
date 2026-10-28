import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/event_categories.dart';
import '../../../core/constants/turkey_cities.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/text_search.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../event_details/data/event.dart';
import '../../following/data/follow_repository.dart';
import '../../moderation/data/block_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../data/event_filter.dart';
import '../data/event_query_repository.dart';
import '../data/home_sections.dart';
import 'city_picker.dart';
import 'event_card.dart';
import 'filter_sheet.dart';
import 'home_widgets.dart';

/// Keşfet (ana sayfa): bannerlar, kategoriler, zaman düğmeleri ve etkinlik şeritleri.
/// Arama yapılınca ya da kategori/tarih seçilince sonuç listesine geçer.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _showAll = false;
  bool _cityInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCityFromProfile());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// İlk açılışta şehir, profildeki şehirdir (geçerliyse). Kullanıcı sonradan değiştirebilir.
  void _initCityFromProfile() {
    if (_cityInitialized || !mounted) return;
    final city = ref.read(currentProfileProvider).valueOrNull?.city;
    if (city == null) return;
    _cityInitialized = true;
    final filter = ref.read(discoverFilterProvider);
    if (filter.city == null && TurkeyCities.isValid(city)) {
      ref.read(discoverFilterProvider.notifier).state = filter.copyWith(city: city);
    }
  }

  void _setFilter(EventFilter filter) {
    ref.read(discoverFilterProvider.notifier).state = filter;
    ref.read(discoverLimitProvider.notifier).state = discoverPageSize;
  }

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

  Future<void> _pickCity(EventFilter filter) async {
    final picked = await showCityPicker(context, selected: filter.city);
    if (picked == null) return;
    _setFilter(picked.isEmpty ? filter.copyWith(clearCity: true) : filter.copyWith(city: picked));
  }

  Future<void> _pickDate(EventFilter filter) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: filter.date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) _setFilter(filter.copyWith(date: picked));
  }

  void _backToHome(EventFilter filter) {
    _searchController.clear();
    setState(() {
      _query = '';
      _showAll = false;
    });
    _setFilter(filter.copyWith(clearCategory: true, clearGroup: true, clearDate: true));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentProfileProvider, (_, __) => _initCityFromProfile());
    final filter = ref.watch(discoverFilterProvider);
    final resultsMode = _query.trim().isNotEmpty || filter.hasNarrowing || _showAll;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: resultsMode ? _buildResults(context, filter) : _buildBrowse(context, filter),
      ),
    );
  }

  // ---------- ortak parçalar ----------

  Widget _header(BuildContext context, EventFilter filter) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'rota',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _pickCity(filter),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 18),
                        const SizedBox(width: 2),
                        Text(
                          filter.city ?? 'Tüm şehirler',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
    );
  }

  // ---------- ana sayfa (şeritler) ----------

  Widget _buildBrowse(BuildContext context, EventFilter filter) {
    final eventsAsync = ref.watch(homeEventsProvider);
    final blocked = ref.watch(blockedUserIdsProvider).valueOrNull ?? const <String>{};
    final followed = (ref.watch(followingListProvider).valueOrNull ?? const <Following>[])
        .map((f) => f.organizerId)
        .toSet();

    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        _header(context, filter),
        const SizedBox(height: 16),
        HomeBanners(
          onCreateEvent: () => context.push(RoutePaths.createEvent),
          onGroups: () => context.push(RoutePaths.groups),
          onSaved: () => context.go(RoutePaths.myEvents),
        ),
        _searchBar(),
        const SectionHeader(title: 'Kategoriler'),
        CategoryRow(
          selectedGroupId: filter.groupId,
          onSelected: (group) => _setFilter(
            filter.copyWith(groupId: group.id, clearCategory: true),
          ),
        ),
        const SectionHeader(title: 'Hangi zamanı planlıyorsun?'),
        TimeChips(
          filter: filter,
          onPreset: (preset) => _setFilter(filter.withPreset(preset)),
          onPickDate: () => _pickDate(filter),
        ),
        ..._eventSections(context, eventsAsync, blocked, followed, filter),
      ],
    );
  }

  List<Widget> _eventSections(
    BuildContext context,
    AsyncValue<List<Event>> eventsAsync,
    Set<String> blocked,
    Set<String> followed,
    EventFilter filter,
  ) {
    final events = eventsAsync.valueOrNull;
    if (events == null) {
      return [
        const SizedBox(height: 40),
        if (eventsAsync.hasError)
          ErrorView(
            message: mapErrorToMessage(eventsAsync.error!),
            onRetry: () => ref.invalidate(homeEventsProvider),
          )
        else
          const LoadingView(),
      ];
    }
    final visible = events.where((e) => !blocked.contains(e.ownerId)).toList();
    if (visible.isEmpty) {
      return [
        const SizedBox(height: 24),
        _EmptyHero(
          city: filter.city,
          onCreate: () => context.push(RoutePaths.createEvent),
          onAllCities: filter.city == null ? null : () => _setFilter(filter.copyWith(clearCity: true)),
        ),
      ];
    }

    final sections = HomeSections.build(visible, followedIds: followed);
    void seeAll() => setState(() => _showAll = true);
    return [
      if (sections.following.isNotEmpty)
        ..._strip('Takip ettiklerim', sections.following, seeAll),
      ..._strip(
        sections.featured.isNotEmpty ? 'Öne çıkan etkinlikler' : 'Yaklaşan etkinlikler',
        sections.featured.isNotEmpty
            ? sections.featured
            : visible.take(HomeSections.stripSize).toList(),
        seeAll,
      ),
      if (sections.mostSaved.isNotEmpty)
        ..._strip('En çok beğenilenler', sections.mostSaved, seeAll),
      if (sections.almostFull.isNotEmpty)
        ..._strip('Dolmak üzere', sections.almostFull, seeAll),
      if (sections.newest.isNotEmpty)
        ..._strip('Yeni eklenenler', sections.newest, seeAll),
      SectionHeader(title: 'Tüm yaklaşan etkinlikler', onSeeAll: seeAll),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            for (final event in visible.take(5))
              EventCard(
                event: event,
                showSave: true,
                onTap: () => context.push(RoutePaths.eventDetails(event.id)),
              ),
            if (visible.length > 5)
              OutlinedButton(onPressed: seeAll, child: const Text('Tümünü göster')),
          ],
        ),
      ),
    ];
  }

  List<Widget> _strip(String title, List<Event> events, VoidCallback onSeeAll) {
    return [
      SectionHeader(title: title, onSeeAll: onSeeAll),
      SizedBox(
        height: 300,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final event = events[index];
            return SizedBox(
              width: 252,
              child: EventCard(
                event: event,
                showSave: true,
                margin: EdgeInsets.zero,
                onTap: () => context.push(RoutePaths.eventDetails(event.id)),
              ),
            );
          },
        ),
      ),
    ];
  }

  // ---------- sonuç listesi ----------

  Widget _buildResults(BuildContext context, EventFilter filter) {
    final limit = ref.watch(discoverLimitProvider);
    final eventsAsync = ref.watch(discoverEventsProvider);
    final blocked = ref.watch(blockedUserIdsProvider).valueOrNull ?? const <String>{};
    final theme = Theme.of(context);

    final chips = <Widget>[
      if (filter.groupId != null)
        InputChip(
          label: Text(EventCategory.groups.firstWhere((g) => g.id == filter.groupId).label),
          onDeleted: () => _setFilter(filter.copyWith(clearGroup: true)),
        ),
      if (filter.categoryId != null)
        InputChip(
          label: Text(EventCategory.byId(filter.categoryId!).label),
          onDeleted: () => _setFilter(filter.copyWith(clearCategory: true)),
        ),
      if (filter.date != null)
        InputChip(
          label: Text(
            filter.preset?.label ?? DateFormatters.dateRange(filter.date!, filter.dateEnd),
          ),
          onDeleted: () => _setFilter(filter.copyWith(clearDate: true)),
        ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Ana sayfa',
                onPressed: () => _backToHome(filter),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  _query.trim().isNotEmpty ? 'Arama sonuçları' : 'Etkinlikler',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: () => _pickCity(filter),
                icon: const Icon(Icons.location_on_outlined, size: 18),
                label: Text(filter.city ?? 'Tüm şehirler'),
              ),
              IconButton(
                tooltip: 'Filtrele',
                onPressed: () => showFilterSheet(context),
                icon: Badge(
                  isLabelVisible: filter.isActive,
                  label: Text('${filter.activeCount}'),
                  child: const Icon(Icons.tune),
                ),
              ),
            ],
          ),
        ),
        _searchBar(),
        if (chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Wrap(spacing: 8, runSpacing: 4, children: chips),
          ),
        const SizedBox(height: 16),
        ..._resultItems(context, filter, limit, eventsAsync, blocked),
      ],
    );
  }

  List<Widget> _resultItems(
    BuildContext context,
    EventFilter filter,
    int limit,
    AsyncValue<List<Event>> eventsAsync,
    Set<String> blocked,
  ) {
    final events = eventsAsync.valueOrNull;
    if (events == null) {
      return [
        if (eventsAsync.hasError)
          ErrorView(
            message: mapErrorToMessage(eventsAsync.error!),
            onRetry: () => ref.invalidate(discoverEventsProvider),
          )
        else
          const LoadingView(),
      ];
    }
    final visible = events
        .where((event) => !blocked.contains(event.ownerId))
        .where(_matchesQuery)
        .toList();
    final canLoadMore = events.length >= limit && filter.groupId == null;

    if (visible.isEmpty) {
      if (_query.trim().isNotEmpty) {
        return [
          EmptyView(
            icon: Icons.search_off,
            title: 'Sonuç bulunamadı',
            message:
                '"${_query.trim()}" için yüklenen etkinliklerde eşleşme yok. Farklı bir sözcük dene'
                '${canLoadMore ? ' veya daha fazla etkinlik yükle' : ''}.',
            actionLabel: canLoadMore ? 'Daha fazla yükle' : null,
            onAction: canLoadMore
                ? () => ref.read(discoverLimitProvider.notifier).state = limit + discoverPageSize
                : null,
          ),
        ];
      }
      return [
        EmptyView(
          icon: Icons.search_off,
          title: 'Bu seçime uyan etkinlik yok',
          message: 'Başka bir tarih ya da kategori dene, ya da ilk etkinliği sen oluştur.',
          actionLabel: 'Etkinlik oluştur',
          onAction: () => context.push(RoutePaths.createEvent),
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            for (final event in visible)
              EventCard(
                event: event,
                showSave: true,
                onTap: () => context.push(RoutePaths.eventDetails(event.id)),
              ),
            if (canLoadMore)
              OutlinedButton(
                onPressed: () => ref.read(discoverLimitProvider.notifier).state =
                    limit + discoverPageSize,
                child: const Text('Daha fazla göster'),
              ),
          ],
        ),
      ),
    ];
  }
}

/// Şehirde hiç etkinlik yokken gösterilen büyük çağrı.
class _EmptyHero extends StatelessWidget {
  const _EmptyHero({required this.city, required this.onCreate, this.onAllCities});

  final String? city;
  final VoidCallback onCreate;
  final VoidCallback? onAllCities;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            const Icon(Icons.explore_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              city == null ? 'Henüz etkinlik yok' : '$city için henüz etkinlik yok',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'İlk etkinliği sen oluştur, diğerleri katılsın.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onCreate, child: const Text('Etkinlik oluştur')),
            if (onAllCities != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onAllCities, child: const Text('Tüm şehirleri göster')),
            ],
          ],
        ),
      ),
    );
  }
}
