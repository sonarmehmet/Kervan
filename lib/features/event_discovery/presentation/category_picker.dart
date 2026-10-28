import 'package:flutter/material.dart';

import '../../../core/constants/event_categories.dart';
import '../../../core/utils/text_search.dart';

/// Tek kategori seçtirir (etkinlik formu, filtre). İptalde `null`; "Temizle" seçilirse boş metin döner.
Future<String?> showCategoryPicker(
  BuildContext context, {
  String? selectedId,
  bool allowClear = false,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CategorySheet(
      selected: <String>{if (selectedId != null) selectedId},
      multi: false,
      allowClear: allowClear,
    ),
  );
}

/// Birden fazla kategori seçtirir (profil ilgi alanları). İptalde `null`.
Future<Set<String>?> showCategoryMultiPicker(
  BuildContext context, {
  required Set<String> selected,
  required int max,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CategorySheet(selected: selected, multi: true, max: max),
  );
}

class _CategorySheet extends StatefulWidget {
  const _CategorySheet({
    required this.selected,
    required this.multi,
    this.allowClear = false,
    this.max = 0,
  });

  final Set<String> selected;
  final bool multi;
  final bool allowClear;
  final int max;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late final Set<String> _selected = <String>{...widget.selected};
  String _query = '';

  bool _matches(EventCategory category) =>
      matchesSearch(_query, [category.label, category.group.label]);

  void _tap(EventCategory category) {
    if (!widget.multi) {
      Navigator.pop(context, category.id);
      return;
    }
    setState(() {
      if (_selected.contains(category.id)) {
        _selected.remove(category.id);
      } else if (_selected.length >= widget.max) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('En fazla ${widget.max} seçim yapabilirsin.')),
        );
      } else {
        _selected.add(category.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.85;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final children = <Widget>[];
    var total = 0;
    for (final group in EventCategory.groups) {
      final items = EventCategory.inGroup(group).where(_matches).toList();
      if (items.isEmpty) continue;
      total += items.length;
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Icon(group.icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                group.label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
      );
      for (final category in items) {
        final isSelected = _selected.contains(category.id);
        children.add(
          ListTile(
            dense: true,
            leading: Icon(category.icon),
            title: Text(category.label),
            trailing: isSelected ? const Icon(Icons.check_circle) : null,
            selected: isSelected,
            onTap: () => _tap(category),
          ),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: false,
                decoration: const InputDecoration(
                  hintText: 'Kategori ara (örn. futbol, yoga, kamp)',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            if (widget.allowClear)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, ''),
                  child: const Text('Seçimi temizle'),
                ),
              ),
            Expanded(
              child: total == 0
                  ? const Center(child: Text('Eşleşen kategori yok.'))
                  : ListView(children: children),
            ),
            if (widget.multi)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      child: Text('Tamam (${_selected.length}/${widget.max})'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
