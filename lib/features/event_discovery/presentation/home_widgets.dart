import 'package:flutter/material.dart';

import '../../../core/constants/event_categories.dart';
import '../../../core/theme/rota_colors.dart';
import '../data/event_filter.dart';
import '../data/time_preset.dart';

/// Şerit başlığı: solda başlık, sağda "Tümü".
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(title, style: theme.textTheme.headlineSmall)),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: const Text('Tümü')),
        ],
      ),
    );
  }
}

/// Kategori grupları: renkli yuvarlaklar, yatay kayar.
class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key, required this.onSelected, this.selectedGroupId});

  final ValueChanged<EventCategoryGroup> onSelected;
  final String? selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = EventCategory.groups;
    return SizedBox(
      height: 132,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final group = groups[index];
          final base = RotaColors.accentAt(index);
          final selected = group.id == selectedGroupId;
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelected(group),
            child: SizedBox(
              width: 88,
              child: Column(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [base, Color.lerp(base, Colors.black, 0.25)!],
                      ),
                      border: selected
                          ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                          : null,
                    ),
                    child: Icon(group.icon, size: 36, color: RotaColors.onAccent(base)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// "Hangi zamanı planlıyorsun?": 2 sütunlu hazır tarih düğmeleri.
class TimeChips extends StatelessWidget {
  const TimeChips({
    super.key,
    required this.filter,
    required this.onPreset,
    required this.onPickDate,
  });

  final EventFilter filter;
  final ValueChanged<TimePreset> onPreset;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final customDate = filter.date != null && filter.preset == null;
    final items = <_ChipItem>[
      for (final preset in TimePreset.values)
        _ChipItem(preset.label, filter.preset == preset, () => onPreset(preset)),
      _ChipItem('Farklı Bir Tarih', customDate, onPickDate),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 3.3,
        children: [for (final item in items) _TimeChip(item: item)],
      ),
    );
  }
}

class _ChipItem {
  const _ChipItem(this.label, this.selected, this.onTap);

  final String label;
  final bool selected;
  final VoidCallback onTap;
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.item});

  final _ChipItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = item.selected ? RotaColors.sun : theme.colorScheme.surfaceContainerLowest;
    final foreground = item.selected ? RotaColors.ink : theme.colorScheme.onSurface;
    return Material(
      color: background,
      shape: StadiumBorder(
        side: BorderSide(
          color: item.selected ? RotaColors.sun : theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: item.onTap,
        child: Center(
          child: Text(
            item.label,
            style: theme.textTheme.titleSmall?.copyWith(color: foreground),
          ),
        ),
      ),
    );
  }
}

/// Üstteki tanıtım kartları (yatay kayar, noktalı gösterge). İçerik uygulamaya aittir.
class HomeBanners extends StatefulWidget {
  const HomeBanners({
    super.key,
    required this.onCreateEvent,
    required this.onGroups,
    required this.onSaved,
  });

  final VoidCallback onCreateEvent;
  final VoidCallback onGroups;
  final VoidCallback onSaved;

  @override
  State<HomeBanners> createState() => _HomeBannersState();
}

class _HomeBannersState extends State<HomeBanners> {
  final _controller = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = <_BannerData>[
      _BannerData(
        title: 'Şehrinin potansiyelini açığa çıkar!',
        text: 'Rota ile çevrendeki etkinlikleri keşfet ya da kendi etkinliğini oluştur.',
        action: 'Etkinlik oluştur',
        color: RotaColors.plum,
        icon: Icons.celebration,
        onTap: widget.onCreateEvent,
      ),
      _BannerData(
        title: 'Birlikte daha eğlenceli',
        text: 'Bir gruba katıl, aynı ilgi alanlarına sahip insanlarla tanış.',
        action: 'Gruplara göz at',
        color: RotaColors.ember,
        icon: Icons.groups,
        onTap: widget.onGroups,
      ),
      _BannerData(
        title: 'Kaçırma, kaydet',
        text: 'Beğendiğin etkinliği yer imine ekle, sonra rahatça karar ver.',
        action: 'Kaydettiklerim',
        color: const Color(0xFF1F6F6B),
        icon: Icons.bookmark,
        onTap: widget.onSaved,
      ),
    ];
    return Column(
      children: [
        SizedBox(
          height: 176,
          child: PageView.builder(
            controller: _controller,
            itemCount: banners.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _BannerCard(data: banners[index]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < banners.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BannerData {
  const _BannerData({
    required this.title,
    required this.text,
    required this.action,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String text;
  final String action;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.data});

  final _BannerData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: data.color,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -22,
              child: Icon(data.icon, size: 150, color: Colors.white.withValues(alpha: 0.16)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: RotaColors.sun,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      data.action,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: RotaColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
