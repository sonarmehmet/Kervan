import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/router/route_names.dart';
import '../../authentication/data/auth_repository.dart';
import '../../event_details/data/event.dart';
import '../../profile/data/profile_repository.dart';
import '../data/join_request.dart';
import '../data/participation_repository.dart';

/// Etkinlik detay ekranındaki katılım alanı.
/// Kullanıcının durumuna göre: sahip işlemleri, talep gönder, talebi geri çek, ayrıl, bilgi kartı.
class ParticipationSection extends ConsumerStatefulWidget {
  const ParticipationSection({super.key, required this.event});

  final Event event;

  @override
  ConsumerState<ParticipationSection> createState() =>
      _ParticipationSectionState();
}

class _ParticipationSectionState extends ConsumerState<ParticipationSection> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (success != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success)),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapErrorToMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendRequest(String uid) {
    final name = ref.read(currentProfileProvider).valueOrNull?.displayName ?? '';
    if (name.isEmpty) {
      throw const AppException('Profil bilgin yüklenemedi. Lütfen tekrar dene.');
    }
    return ref.read(participationRepositoryProvider).sendRequest(
          eventId: widget.event.id,
          uid: uid,
          userName: name,
        );
  }

  Future<void> _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Etkinlikten ayrılmak istiyor musun?'),
        content: const Text('Yerin boşalır ve etkinlik sahibi bunu görür.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            child: const Text('Ayrıl'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(
      () => ref
          .read(participationRepositoryProvider)
          .leave(eventId: widget.event.id),
      success: 'Etkinlikten ayrıldın.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    if (uid == null) return const SizedBox.shrink();

    if (uid == event.ownerId) return _OwnerActions(event: event);

    final isParticipant =
        ref.watch(isParticipantProvider(event.id)).valueOrNull ?? false;
    final request = ref.watch(myRequestProvider(event.id)).valueOrNull;

    if (isParticipant) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InfoCard(
            icon: Icons.check_circle,
            text: 'Bu etkinliğe katılıyorsun.',
            positive: true,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                context.push(RoutePaths.eventParticipants(event.id)),
            icon: const Icon(Icons.groups_outlined),
            label: const Text('Katılımcıları gör'),
          ),
          const SizedBox(height: 8),
          if (!event.hasStarted && !event.isCancelled)
            TextButton(
              onPressed: _busy ? null : _confirmLeave,
              child: const Text('Etkinlikten ayrıl'),
            ),
        ],
      );
    }

    final status = request?.status;
    if (status == RequestStatus.pending) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InfoCard(
            icon: Icons.hourglass_top,
            text: 'Talebin etkinlik sahibinin onayını bekliyor.',
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(
                      () => ref.read(participationRepositoryProvider).cancelRequest(
                            eventId: event.id,
                            uid: uid,
                          ),
                      success: 'Talebin geri çekildi.',
                    ),
            child: const Text('Talebi geri çek'),
          ),
        ],
      );
    }
    if (status == RequestStatus.rejected) {
      return const _InfoCard(
        icon: Icons.cancel_outlined,
        text: 'Katılım talebin reddedildi.',
      );
    }
    if (status == RequestStatus.approved) {
      return const _InfoCard(
        icon: Icons.check_circle_outline,
        text: 'Talebin onaylandı. Katılımcı listesi güncelleniyor...',
        positive: true,
      );
    }

    // Talep yok veya geri çekilmiş.
    if (event.isCancelled) {
      return const _InfoCard(icon: Icons.event_busy, text: 'Bu etkinlik iptal edildi.');
    }
    if (event.hasStarted) {
      return const _InfoCard(
        icon: Icons.history,
        text: 'Etkinliğin başlangıç zamanı geçti.',
      );
    }
    if (event.isFull) {
      return const _InfoCard(icon: Icons.group_off, text: 'Etkinliğin kapasitesi dolu.');
    }
    return FilledButton.icon(
      onPressed: _busy
          ? null
          : () => _run(
                () => _sendRequest(uid),
                success: 'Katılım talebin gönderildi.',
              ),
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.person_add_alt_1),
      label: const Text('Katılma talebi gönder'),
    );
  }
}

class _OwnerActions extends ConsumerWidget {
  const _OwnerActions({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = (ref.watch(eventRequestsProvider(event.id)).valueOrNull ??
            const <JoinRequest>[])
        .where((request) => request.status == RequestStatus.pending)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => context.push(RoutePaths.eventRequests(event.id)),
          icon: Badge(
            isLabelVisible: pending > 0,
            label: Text('$pending'),
            child: const Icon(Icons.inbox_outlined),
          ),
          label: const Text('Katılım talepleri'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => context.push(RoutePaths.eventParticipants(event.id)),
          icon: const Icon(Icons.groups_outlined),
          label: Text('Katılımcılar (${event.acceptedCount})'),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.text,
    this.positive = false,
  });

  final IconData icon;
  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = positive
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = positive
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: foreground))),
        ],
      ),
    );
  }
}
