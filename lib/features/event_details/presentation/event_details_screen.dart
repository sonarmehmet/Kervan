import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/event_categories.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../authentication/data/auth_repository.dart';
import '../../event_creation/data/event_repository.dart';
import '../../event_creation/data/event_validators.dart';
import '../../location/presentation/event_location_card.dart';
import '../../moderation/data/report_repository.dart';
import '../../moderation/presentation/block_user_dialog.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../../participation/data/participation_repository.dart';
import '../../participation/presentation/participation_section.dart';
import '../../following/presentation/follow_button.dart';
import '../../saved/presentation/save_button.dart';
import '../../ratings/presentation/event_rating_section.dart';
import '../../ratings/presentation/rating_widgets.dart';
import '../data/event.dart';
import '../data/event_share.dart';

class EventDetailsScreen extends ConsumerWidget {
  const EventDetailsScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventProvider(eventId));
    final event = eventAsync.valueOrNull;

    Widget body;
    if (eventAsync.hasError && event == null) {
      body = ErrorView(
        message: mapErrorToMessage(eventAsync.error!),
        onRetry: () => ref.invalidate(eventProvider(eventId)),
      );
    } else if (eventAsync.isLoading && event == null) {
      body = const LoadingView();
    } else if (event == null) {
      body = const EmptyView(
        icon: Icons.event_busy,
        title: 'Etkinlik bulunamadı',
        message: 'Silinmiş veya kaldırılmış olabilir.',
      );
    } else {
      body = _EventBody(event: event);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinlik'),
        actions: [
          if (event != null) SaveButton(eventId: event.id),
          if (event != null) _EventMenu(event: event),
        ],
      ),
      body: body,
    );
  }
}

class _EventBody extends ConsumerWidget {
  const _EventBody({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final isOwner = uid != null && uid == event.ownerId;
    final isParticipant =
        ref.watch(isParticipantProvider(event.id)).valueOrNull ?? false;
    final category = EventCategory.byId(event.category);
    final progress =
        event.capacity == 0 ? 0.0 : event.acceptedCount / event.capacity;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (event.hasImage) ...[
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                event.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Wrap(
          spacing: 8,
          children: [
            Chip(
              avatar: Icon(category.icon, size: 18),
              label: Text(category.label),
            ),
            if (event.isCancelled)
              Chip(
                label: const Text('İptal edildi'),
                backgroundColor: theme.colorScheme.errorContainer,
              ),
            if (event.groupId != null)
              ActionChip(
                avatar: const Icon(Icons.groups, size: 18),
                label: Text(event.groupName ?? 'Grup'),
                onPressed: () => context.push(RoutePaths.groupDetails(event.groupId!)),
              ),
            if (event.seriesId != null)
              const Chip(
                avatar: Icon(Icons.repeat, size: 18),
                label: Text('Tekrarlayan seri'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(event.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        _DetailRow(
          icon: Icons.schedule,
          text: event.durationMinutes == null
              ? DateFormatters.eventDateTime(event.startsAt)
              : '${DateFormatters.eventDateTime(event.startsAt)} · ${durationLabel(event.durationMinutes!)}',
        ),
        if (event.costNote.isNotEmpty)
          _DetailRow(icon: Icons.payments_outlined, text: event.costNote),
        _DetailRow(
          icon: Icons.person_outline,
          text: 'Düzenleyen: ${event.ownerName}',
        ),
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 8),
          child: Row(
            children: [
              RatingBadge(userId: event.ownerId, asOrganizer: true),
              const Spacer(),
              FollowButton(organizerId: event.ownerId, organizerName: event.ownerName),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Katılımcılar', style: theme.textTheme.titleSmall),
            Text('${event.acceptedCount}/${event.capacity}'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0).toDouble(),
            minHeight: 8,
          ),
        ),
        if (event.description.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Açıklama', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(event.description),
        ],
        if (event.terms.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Katılım koşulları', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(event.terms)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        EventLocationCard(
          event: event,
          canViewAddress: isOwner || isParticipant,
        ),
        const SizedBox(height: 24),
        ParticipationSection(event: event),
        if (uid != null) ...[
          const SizedBox(height: 16),
          EventRatingSection(
            event: event,
            uid: uid,
            isOwner: isOwner,
            isParticipant: isParticipant,
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

enum _MenuAction { share, calendar, edit, cancel, report, block }

class _EventMenu extends ConsumerWidget {
  const _EventMenu({required this.event});

  final Event event;

  Future<void> _cancelEvent(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Etkinlik iptal edilsin mi?'),
        content: const Text(
          'Katılımcılara ve bekleyen talep sahiplerine bildirim gider. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            child: const Text('Etkinliği iptal et'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(eventRepositoryProvider).cancelEvent(event.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Etkinlik iptal edildi.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapErrorToMessage(error))),
      );
    }
  }

  Future<void> _onSelected(
    BuildContext context,
    WidgetRef ref,
    _MenuAction action,
  ) async {
    switch (action) {
      case _MenuAction.share:
        await Share.share(buildShareText(event), subject: event.title);
      case _MenuAction.calendar:
        var opened = false;
        try {
          opened = await launchUrl(calendarUri(event), mode: LaunchMode.externalApplication);
        } catch (_) {
          opened = false;
        }
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Takvim açılamadı.')),
          );
        }
      case _MenuAction.edit:
        await context.push(RoutePaths.editEvent(event.id));
      case _MenuAction.cancel:
        await _cancelEvent(context, ref);
      case _MenuAction.report:
        await showReportSheet(
          context,
          type: ReportTargetType.event,
          targetId: event.id,
        );
      case _MenuAction.block:
        final blocked = await confirmAndBlockUser(
          context,
          ref,
          userId: event.ownerId,
          userName: event.ownerName,
        );
        if (blocked && context.mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final isOwner = uid != null && uid == event.ownerId;

    return PopupMenuButton<_MenuAction>(
      onSelected: (action) => _onSelected(context, ref, action),
      itemBuilder: (context) => [
        const PopupMenuItem(value: _MenuAction.share, child: Text('Paylaş')),
        const PopupMenuItem(value: _MenuAction.calendar, child: Text('Takvime ekle')),
        if (isOwner && !event.isCancelled) ...const [
          PopupMenuItem(value: _MenuAction.edit, child: Text('Düzenle')),
          PopupMenuItem(value: _MenuAction.cancel, child: Text('Etkinliği iptal et')),
        ],
        if (!isOwner) ...const [
          PopupMenuItem(value: _MenuAction.report, child: Text('Şikâyet et')),
          PopupMenuItem(value: _MenuAction.block, child: Text('Düzenleyeni engelle')),
        ],
      ],
    );
  }
}
