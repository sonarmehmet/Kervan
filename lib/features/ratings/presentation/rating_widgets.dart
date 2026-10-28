import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_stats.dart';
import '../data/ratings_repository.dart';

/// Kullanıcının puan özeti: "★ 4,6 (12)" ya da yeterli puan yoksa "Yeni".
/// [asOrganizer] true ise düzenleyen puanı, false ise katılımcı puanı gösterilir.
class RatingBadge extends ConsumerWidget {
  const RatingBadge({super.key, required this.userId, required this.asOrganizer});

  final String userId;
  final bool asOrganizer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider(userId)).valueOrNull ?? UserStats.empty;
    return RatingText(
      average: asOrganizer ? stats.organizerAverage : stats.participantAverage,
      count: asOrganizer ? stats.organizerCount : stats.participantCount,
    );
  }
}

/// Saf görünüm (test edilebilir).
class RatingText extends StatelessWidget {
  const RatingText({super.key, required this.average, required this.count});

  final double? average;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    if (average == null) {
      return Text('Yeni · henüz yeterli puan yok', style: style);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, size: 16, color: Color(0xFFF5A623)),
        const SizedBox(width: 2),
        Text('${formatRating(average!)} ($count)', style: style),
      ],
    );
  }
}

/// 1-5 yıldız seçici.
class StarPicker extends StatelessWidget {
  const StarPicker({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: '$i yıldız',
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(i),
            icon: Icon(
              i <= value ? Icons.star : Icons.star_border,
              color: const Color(0xFFF5A623),
            ),
          ),
      ],
    );
  }
}
