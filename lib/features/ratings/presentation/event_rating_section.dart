import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../event_details/data/event.dart';
import '../../participation/data/participation_repository.dart';
import '../data/ratings_repository.dart';
import 'rating_widgets.dart';

/// Etkinlikten sonra anonim değerlendirme alanı.
///  - Katılımcı: düzenleyeni puanlar.
///  - Düzenleyen: onaylı katılımcıları puanlar.
/// Puanı veren kişi hedefe asla gösterilmez; hedef yalnızca ortalamayı görür (en az 3 puanda).
class EventRatingSection extends ConsumerWidget {
  const EventRatingSection({
    super.key,
    required this.event,
    required this.uid,
    required this.isOwner,
    required this.isParticipant,
  });

  final Event event;
  final String uid;
  final bool isOwner;
  final bool isParticipant;

  /// Sunucudaki 30 günlük sınırla aynı.
  static const Duration window = Duration(days: 30);

  static bool isOpen(Event event, DateTime now) =>
      !event.isCancelled &&
      !event.startsAt.isAfter(now) &&
      now.difference(event.startsAt) <= window;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(isOwner || isParticipant) || !isOpen(event, DateTime.now())) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final rated = ref.watch(myRatedTargetsProvider(event.id)).valueOrNull ?? const <String>{};

    final rows = <Widget>[];
    if (isOwner) {
      final participants =
          ref.watch(eventParticipantsProvider(event.id)).valueOrNull ?? const [];
      for (final p in participants) {
        rows.add(
          _RateRow(
            eventId: event.id,
            targetId: p.userId,
            label: p.userName,
            alreadyRated: rated.contains(p.userId),
          ),
        );
      }
      if (rows.isEmpty) return const SizedBox.shrink();
    } else {
      rows.add(
        _RateRow(
          eventId: event.id,
          targetId: event.ownerId,
          label: 'Düzenleyen: ${event.ownerName}',
          alreadyRated: rated.contains(event.ownerId),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_rate_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Değerlendir', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Puanın anonimdir: karşı taraf kimin puan verdiğini göremez; yalnızca ortalamayı '
              'görür (en az 3 puan olunca).',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _RateRow extends ConsumerStatefulWidget {
  const _RateRow({
    required this.eventId,
    required this.targetId,
    required this.label,
    required this.alreadyRated,
  });

  final String eventId;
  final String targetId;
  final String label;
  final bool alreadyRated;

  @override
  ConsumerState<_RateRow> createState() => _RateRowState();
}

class _RateRowState extends ConsumerState<_RateRow> {
  int _stars = 0;
  bool _sending = false;

  Future<void> _submit() async {
    if (_stars == 0) return;
    setState(() => _sending = true);
    try {
      await ref.read(ratingsRepositoryProvider).submit(
            eventId: widget.eventId,
            targetUserId: widget.targetId,
            stars: _stars,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değerlendirmen anonim olarak kaydedildi.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapErrorToMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.alreadyRated) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.check_circle, color: theme.colorScheme.primary),
        title: Text(widget.label),
        subtitle: const Text('Değerlendirdin'),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: theme.textTheme.titleSmall),
          Row(
            children: [
              StarPicker(value: _stars, onChanged: (v) => setState(() => _stars = v)),
              const Spacer(),
              FilledButton.tonal(
                onPressed: (_stars == 0 || _sending) ? null : _submit,
                child: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Gönder'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
