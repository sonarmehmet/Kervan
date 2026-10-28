import 'package:flutter/material.dart';

import '../../../core/constants/event_categories.dart';
import '../../../core/theme/rota_colors.dart';
import '../../../core/widgets/date_badge.dart';
import '../../event_details/data/event.dart';
import '../../saved/presentation/save_button.dart';

/// Etkinlik kartı: kapak (fotoğraf ya da renkli kategori zemini), tarih rozeti, başlık,
/// katılımcı ve konum. Listede tam genişlikte, şeritlerde sabit genişlikte kullanılır.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.showSave = false,
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  final Event event;
  final VoidCallback onTap;

  /// Kapağın köşesinde kaydet (yer imi) düğmesini göster. Oturum ve Firebase gerektirir.
  final bool showSave;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = event.isCancelled || event.hasStarted;
    final participants = event.acceptedCount == 0
        ? 'İlk katılan sen ol'
        : '${event.acceptedCount} kişi katılıyor';

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: margin,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: muted ? 0.65 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    EventCover(event: event),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: DateBadge(date: event.startsAt, size: 58),
                    ),
                    if (showSave)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: SaveButton(eventId: event.id, filled: true),
                      ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: _StatusBadge(event: event),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _InfoLine(icon: Icons.people_alt_outlined, text: participants),
                    const SizedBox(height: 4),
                    _InfoLine(
                      icon: Icons.location_on_outlined,
                      text: event.locationLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etkinlik kapağı: fotoğraf varsa o, yoksa kategori grubunun rengiyle zemin ve büyük simge.
class EventCover extends StatelessWidget {
  const EventCover({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final fallback = _CategoryCover(categoryId: event.category);
    if (!event.hasImage) return fallback;
    return Image.network(
      event.imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _CategoryCover extends StatelessWidget {
  const _CategoryCover({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final category = EventCategory.byId(categoryId);
    final groupIndex = EventCategory.groups.indexWhere((g) => g.id == category.group.id);
    final base = RotaColors.accentAt(groupIndex < 0 ? 0 : groupIndex);
    final onBase = RotaColors.onAccent(base);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.black, 0.28)!],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 14, bottom: 10),
          child: Icon(category.icon, size: 84, color: onBase.withValues(alpha: 0.28)),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String label;
    Color background;
    Color foreground;
    if (event.isCancelled) {
      label = 'İptal';
      background = theme.colorScheme.errorContainer;
      foreground = theme.colorScheme.onErrorContainer;
    } else if (event.hasStarted) {
      label = 'Geçti';
      background = theme.colorScheme.surfaceContainerHighest;
      foreground = theme.colorScheme.onSurfaceVariant;
    } else if (event.isFull) {
      label = 'Dolu';
      background = RotaColors.ember;
      foreground = Colors.white;
    } else {
      label = '${event.acceptedCount}/${event.capacity}';
      background = RotaColors.ink;
      foreground = RotaColors.paper;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
