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
import '../../moderation/data/block_repository.dart';
import '../data/group.dart';
import '../data/group_repository.dart';
import 'group_card.dart';

/// Gruplar: kitap kulübü, koşu grubu gibi kalıcı topluluklar. Arama + "Gruplarım" süzgeci.
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  final _controller = TextEditingController();
  String _query = '';
  bool _onlyMine = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(Group group) {
    final category = EventCategory.byId(group.category);
    return matchesSearch(_query, [group.name, group.description, group.city, category.label, category.group.label]);
  }

  @override
  Widget build(BuildContext context) {
    final async = _onlyMine ? ref.watch(myGroupsProvider) : ref.watch(activeGroupsProvider);
    final blocked = ref.watch(blockedUserIdsProvider).valueOrNull ?? const <String>{};
    final groups = async.valueOrNull;

    Widget body;
    if (groups == null) {
      body = async.hasError
          ? ErrorView(
              message: mapErrorToMessage(async.error!),
              onRetry: () {
                ref.invalidate(myGroupsProvider);
                ref.invalidate(activeGroupsProvider);
              },
            )
          : const LoadingView();
    } else {
      final visible = groups
          .where((g) => !blocked.contains(g.ownerId))
          .where(_matches)
          .toList();
      if (visible.isEmpty) {
        body = EmptyView(
          icon: Icons.groups_outlined,
          title: _onlyMine ? 'Henüz bir gruba üye değilsin' : 'Grup bulunamadı',
          message: _query.isNotEmpty
              ? 'Farklı bir arama dene.'
              : 'İlk grubu sen kur, benzer ilgi alanlarındaki insanlar katılsın.',
          actionLabel: 'Grup oluştur',
          onAction: () => context.push(RoutePaths.createGroup),
        );
      } else {
        body = ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final group = visible[index];
            return GroupCard(
              group: group,
              onTap: () => context.push(RoutePaths.groupDetails(group.id)),
            );
          },
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gruplar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.createGroup),
        icon: const Icon(Icons.add),
        label: const Text('Grup oluştur'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              controller: _controller,
              hintText: 'Grup, kategori veya şehir ara',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll<double>(0),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tümü'),
                  selected: !_onlyMine,
                  onSelected: (_) => setState(() => _onlyMine = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Gruplarım'),
                  selected: _onlyMine,
                  onSelected: (_) => setState(() => _onlyMine = true),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
