import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/event_categories.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../authentication/data/auth_repository.dart';
import '../../event_discovery/presentation/event_card.dart';
import '../../moderation/data/report_repository.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../../ratings/presentation/rating_widgets.dart';
import '../data/group.dart';
import '../data/group_repository.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  const GroupDetailsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

enum _GroupMenu { edit, close, report }

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (success != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapErrorToMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmClose(Group group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Grup kapatılsın mı?'),
        content: const Text('Kapatılan grup listelerde görünmez ve yeni üye alamaz. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Grubu kapat')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => ref.read(groupRepositoryProvider).close(group.id), success: 'Grup kapatıldı.');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(groupProvider(widget.groupId));
    final group = async.valueOrNull;
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final isOwner = uid != null && group != null && group.ownerId == uid;
    final isMember = ref.watch(isGroupMemberProvider(widget.groupId)).valueOrNull ?? false;
    final eventsAsync = ref.watch(groupEventsProvider(widget.groupId));
    final theme = Theme.of(context);

    Widget body;
    if (group == null) {
      body = async.hasError
          ? ErrorView(
              message: mapErrorToMessage(async.error!),
              onRetry: () => ref.invalidate(groupProvider(widget.groupId)),
            )
          : (async.isLoading
              ? const LoadingView()
              : const EmptyView(icon: Icons.groups_outlined, title: 'Grup bulunamadı'));
    } else {
      final category = EventCategory.byId(group.category);
      final events = eventsAsync.valueOrNull ?? const [];
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              Chip(avatar: Icon(category.icon, size: 18), label: Text(category.label)),
              Chip(avatar: const Icon(Icons.location_on_outlined, size: 18), label: Text(group.city)),
              if (group.isClosed)
                Chip(label: const Text('Kapalı'), backgroundColor: theme.colorScheme.errorContainer),
            ],
          ),
          const SizedBox(height: 8),
          Text(group.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 6),
              Text('Kuran: ${group.ownerName}'),
              const SizedBox(width: 12),
              RatingBadge(userId: group.ownerId, asOrganizer: true),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 18),
              const SizedBox(width: 6),
              Text('${group.memberCount} üye'),
            ],
          ),
          if (group.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(group.description),
          ],
          const SizedBox(height: 16),
          if (uid != null && !group.isClosed)
            if (isOwner)
              FilledButton.icon(
                onPressed: () => context.push('${RoutePaths.createEvent}?groupId=${group.id}'),
                icon: const Icon(Icons.add),
                label: const Text('Bu grup için etkinlik oluştur'),
              )
            else if (isMember)
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _run(() => ref.read(groupRepositoryProvider).leave(group.id), success: 'Gruptan ayrıldın.'),
                child: const Text('Gruptan ayrıl'),
              )
            else
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(() => ref.read(groupRepositoryProvider).join(group.id), success: 'Gruba katıldın.'),
                icon: const Icon(Icons.group_add),
                label: const Text('Gruba katıl'),
              ),
          const SizedBox(height: 24),
          Text('Yaklaşan etkinlikler', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (eventsAsync.hasError)
            Text(mapErrorToMessage(eventsAsync.error!))
          else if (events.isEmpty)
            const Text('Bu grup için planlanmış etkinlik yok.')
          else
            for (final event in events)
              EventCard(event: event, onTap: () => context.push(RoutePaths.eventDetails(event.id))),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grup'),
        actions: [
          if (group != null && uid != null)
            PopupMenuButton<_GroupMenu>(
              onSelected: (action) async {
                switch (action) {
                  case _GroupMenu.edit:
                    await context.push(RoutePaths.editGroup(group.id));
                  case _GroupMenu.close:
                    await _confirmClose(group);
                  case _GroupMenu.report:
                    await showReportSheet(context, type: ReportTargetType.group, targetId: group.id);
                }
              },
              itemBuilder: (context) => [
                if (isOwner && !group.isClosed) ...const [
                  PopupMenuItem(value: _GroupMenu.edit, child: Text('Düzenle')),
                  PopupMenuItem(value: _GroupMenu.close, child: Text('Grubu kapat')),
                ],
                if (!isOwner) const PopupMenuItem(value: _GroupMenu.report, child: Text('Şikâyet et')),
              ],
            ),
        ],
      ),
      body: body,
    );
  }
}
