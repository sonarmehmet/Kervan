import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/event_categories.dart';
import '../../../core/constants/turkey_cities.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatters.dart';
import '../data/event_filter.dart';
import 'category_picker.dart';
import '../data/event_query_repository.dart';

/// Şehir, kategori ve tarih filtresi alt sayfası.
Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late EventFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(discoverFilterProvider);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _draft = _draft.copyWith(date: picked));
    }
  }

  void _apply() {
    ref.read(discoverFilterProvider.notifier).state = _draft;
    ref.read(discoverLimitProvider.notifier).state = discoverPageSize;
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() => _draft = const EventFilter());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filtrele', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _draft.city,
                isExpanded: true,
                decoration: AppTheme.inputDecoration(label: 'Şehir'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tüm şehirler'),
                  ),
                  for (final city in TurkeyCities.all)
                    DropdownMenuItem<String?>(value: city, child: Text(city)),
                ],
                onChanged: (value) => setState(
                  () => _draft = value == null
                      ? _draft.copyWith(clearCity: true)
                      : _draft.copyWith(city: value),
                ),
              ),
              const SizedBox(height: 16),
              Text('Kategori', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showCategoryPicker(
                    context,
                    selectedId: _draft.categoryId,
                    allowClear: _draft.categoryId != null,
                  );
                  if (picked == null) return;
                  setState(
                    () => _draft = picked.isEmpty
                        ? _draft.copyWith(clearCategory: true, clearGroup: true)
                        : _draft.copyWith(categoryId: picked, clearGroup: true),
                  );
                },
                icon: Icon(
                  _draft.categoryId != null
                      ? EventCategory.byId(_draft.categoryId!).icon
                      : Icons.category_outlined,
                ),
                label: Text(
                  _draft.categoryId != null
                      ? EventCategory.byId(_draft.categoryId!).label
                      : _draft.groupId != null
                          ? EventCategory.groups
                              .firstWhere((g) => g.id == _draft.groupId)
                              .label
                          : 'Kategori seç',
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event),
                label: Text(
                  _draft.date == null
                      ? 'Tarih seç'
                      : DateFormatters.dateRange(_draft.date!, _draft.dateEnd),
                ),
              ),
              if (_draft.date != null)
                TextButton(
                  onPressed: () =>
                      setState(() => _draft = _draft.copyWith(clearDate: true)),
                  child: const Text('Tarihi temizle'),
                ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _apply, child: const Text('Uygula')),
              const SizedBox(height: 8),
              TextButton(onPressed: _reset, child: const Text('Hepsini temizle')),
            ],
          ),
        ),
      ),
    );
  }
}
