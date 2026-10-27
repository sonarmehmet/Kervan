import 'package:flutter/material.dart';

import '../../../core/constants/event_categories.dart';
import '../../../core/constants/turkey_cities.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatters.dart';
import '../../event_details/data/event.dart';
import '../../event_discovery/presentation/category_picker.dart';
import '../../groups/data/group.dart';
import '../data/event_input.dart';
import '../data/recurrence.dart';
import '../data/event_validators.dart';

/// Etkinlik oluşturma ve düzenleme için ortak form.
class EventForm extends StatefulWidget {
  const EventForm({
    super.key,
    this.initial,
    this.initialAddress,
    this.minCapacity = 1,
    this.ownedGroups = const <Group>[],
    this.initialGroupId,
    required this.submitLabel,
    required this.onSubmit,
  });

  /// Düzenlemede mevcut etkinlik.
  final Event? initial;
  final String? initialAddress;

  /// Düzenlemede onaylı katılımcı sayısı: kapasite bunun altına inemez.
  final int minCapacity;

  /// Yalnızca oluşturmada: sahibi olduğum gruplar (etkinlik bir gruba bağlanabilir).
  final List<Group> ownedGroups;
  final String? initialGroupId;
  final String submitLabel;

  /// Hata fırlatırsa form mesajı gösterir ve düzenlemeye devam ettirir.
  final Future<void> Function(EventInput input) onSubmit;

  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _districtController;
  late final TextEditingController _capacityController;
  late final TextEditingController _addressController;

  String? _category;
  String? _city;
  String? _groupId;
  Recurrence _recurrence = Recurrence.none;
  int _occurrences = 4;
  DateTime? _startsAt;
  String? _categoryError;
  String? _dateError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descriptionController =
        TextEditingController(text: initial?.description ?? '');
    _districtController = TextEditingController(text: initial?.district ?? '');
    _capacityController =
        TextEditingController(text: '${initial?.capacity ?? 10}');
    _addressController =
        TextEditingController(text: widget.initialAddress ?? '');
    _category = (initial != null && EventCategory.isValidId(initial.category))
        ? initial.category
        : null;
    _city = (initial != null && TurkeyCities.isValid(initial.city))
        ? initial.city
        : null;
    _startsAt = initial?.startsAt;
    _groupId = widget.initialGroupId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _districtController.dispose();
    _capacityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Group? get _selectedGroup {
    if (widget.initial != null || _groupId == null) return null;
    for (final group in widget.ownedGroups) {
      if (group.id == _groupId) return group;
    }
    return null;
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final suggested = _startsAt ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: suggested.isBefore(now) ? now : suggested,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(suggested),
    );
    if (time == null || !mounted) return;
    setState(() {
      _startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _dateError = null;
    });
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    final categoryError = _category == null ? 'Kategori seç.' : null;
    final dateError = EventValidators.startsAt(
      _startsAt,
      unchangedFrom: widget.initial?.startsAt,
    );
    setState(() {
      _categoryError = categoryError;
      _dateError = dateError;
    });
    if (!formValid || categoryError != null || dateError != null) return;

    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        EventInput(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category!,
          city: _city!,
          district: _districtController.text.trim(),
          startsAt: _startsAt!,
          capacity: int.parse(_capacityController.text.trim()),
          address: _addressController.text.trim(),
          recurrence: widget.initial == null ? _recurrence : Recurrence.none,
          occurrences: _recurrence == Recurrence.none ? 1 : _occurrences,
          groupId: _selectedGroup?.id,
          groupName: _selectedGroup?.name,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapErrorToMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            maxLength: EventLimits.titleMax,
            decoration: AppTheme.inputDecoration(
              label: 'Başlık',
              hint: 'Örn. Fırat kenarında yoga',
            ),
            validator: EventValidators.title,
          ),
          const SizedBox(height: 8),
          Text('Kategori', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked =
                  await showCategoryPicker(context, selectedId: _category);
              if (picked == null || picked.isEmpty) return;
              setState(() {
                _category = picked;
                _categoryError = null;
              });
            },
            child: InputDecorator(
              decoration: AppTheme.inputDecoration(label: 'Kategori').copyWith(
                suffixIcon: const Icon(Icons.arrow_drop_down),
                errorText: null,
              ),
              child: _category == null
                  ? Text(
                      'Kategori seç (148 seçenek, aranabilir)',
                      style: TextStyle(color: theme.hintColor),
                    )
                  : Row(
                      children: [
                        Icon(EventCategory.byId(_category!).icon, size: 20),
                        const SizedBox(width: 8),
                        Flexible(child: Text(EventCategory.byId(_category!).label)),
                      ],
                    ),
            ),
          ),
          if (_categoryError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                _categoryError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickDateTime,
            child: InputDecorator(
              decoration: AppTheme.inputDecoration(label: 'Tarih ve saat')
                  .copyWith(
                errorText: _dateError,
                suffixIcon: const Icon(Icons.event),
              ),
              child: Text(
                _startsAt == null
                    ? 'Seçmek için dokun'
                    : DateFormatters.eventDateTime(_startsAt!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _city,
            isExpanded: true,
            decoration: AppTheme.inputDecoration(label: 'Şehir'),
            items: [
              for (final city in TurkeyCities.all)
                DropdownMenuItem<String>(value: city, child: Text(city)),
            ],
            onChanged: (value) => setState(() => _city = value),
            validator: (value) => value == null ? 'Şehir seç.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _districtController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            maxLength: EventLimits.districtMax,
            decoration: AppTheme.inputDecoration(
              label: 'İlçe (herkese açık)',
              hint: 'Örn. Merkez',
            ),
            validator: EventValidators.district,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _addressController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            maxLength: EventLimits.addressMax,
            decoration: AppTheme.inputDecoration(
              label: 'Buluşma adresi',
              hint: 'Mahalle, sokak, tarif...',
            ),
            validator: EventValidators.address,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 16),
            child: Text(
              'Tam adres herkese açık değildir. Yalnızca katılımını onayladığın kişiler görür.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextFormField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: AppTheme.inputDecoration(
              label: 'Kapasite (kişi)',
              hint: '${EventLimits.capacityMin}-${EventLimits.capacityMax}',
            ),
            validator: (value) => EventValidators.capacity(
              value,
              minCapacity: widget.minCapacity,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 5,
            maxLength: EventLimits.descriptionMax,
            textCapitalization: TextCapitalization.sentences,
            decoration: AppTheme.inputDecoration(
              label: 'Açıklama (isteğe bağlı)',
              hint: 'Neler yapacaksınız, ne getirmeli?',
            ),
            validator: EventValidators.description,
          ),
          if (widget.initial == null) ...[
            if (widget.ownedGroups.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _selectedGroup?.id,
                isExpanded: true,
                decoration: AppTheme.inputDecoration(label: 'Grup (isteğe bağlı)'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Grup yok')),
                  for (final group in widget.ownedGroups)
                    DropdownMenuItem<String?>(value: group.id, child: Text(group.name)),
                ],
                onChanged: (value) => setState(() => _groupId = value),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  'Gruba bağlı etkinlikte grup üyelerine bildirim gider.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<Recurrence>(
              initialValue: _recurrence,
              isExpanded: true,
              decoration: AppTheme.inputDecoration(label: 'Tekrar'),
              items: [
                for (final rule in Recurrence.values)
                  DropdownMenuItem<Recurrence>(value: rule, child: Text(rule.label)),
              ],
              onChanged: (value) => setState(() => _recurrence = value ?? Recurrence.none),
            ),
            if (_recurrence != Recurrence.none) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _occurrences,
                decoration: AppTheme.inputDecoration(label: 'Toplam etkinlik sayısı'),
                items: [
                  for (var n = RecurrenceLimits.minOccurrences; n <= RecurrenceLimits.maxOccurrences; n++)
                    DropdownMenuItem<int>(value: n, child: Text('$n etkinlik')),
                ],
                onChanged: (value) => setState(() => _occurrences = value ?? 4),
              ),
              if (_startsAt != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 6),
                  child: Text(
                    'Tarihler: ${occurrenceDates(_startsAt!, _recurrence, _occurrences).take(3).map(DateFormatters.shortDate).join(', ')}'
                    '${_occurrences > 3 ? ' ...' : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  'Her tarih ayrı bir etkinlik olur; istediğini ayrı ayrı iptal edebilirsin.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
