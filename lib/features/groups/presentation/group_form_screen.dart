import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/event_categories.dart';
import '../../../core/constants/turkey_cities.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../event_discovery/presentation/category_picker.dart';
import '../data/group.dart';
import '../data/group_repository.dart';

/// Grup oluşturma ve düzenleme ([group] verilirse düzenleme).
class GroupFormScreen extends ConsumerStatefulWidget {
  const GroupFormScreen({super.key, this.group});

  final Group? group;

  @override
  ConsumerState<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends ConsumerState<GroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.group?.name ?? '');
  late final _descriptionController = TextEditingController(text: widget.group?.description ?? '');
  late String? _category = (widget.group != null && EventCategory.isValidId(widget.group!.category))
      ? widget.group!.category
      : null;
  late String? _city =
      (widget.group != null && TurkeyCities.isValid(widget.group!.city)) ? widget.group!.city : null;
  String? _categoryError;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _categoryError = _category == null ? 'Kategori seç.' : null);
    if (!valid || _category == null) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(groupRepositoryProvider);
      final existing = widget.group;
      if (existing == null) {
        final id = await repo.create(
          name: _nameController.text,
          description: _descriptionController.text,
          category: _category!,
          city: _city!,
        );
        if (mounted) context.pushReplacement(RoutePaths.groupDetails(id));
      } else {
        await repo.update(
          existing.id,
          name: _nameController.text,
          description: _descriptionController.text,
          category: _category!,
          city: _city!,
        );
        if (mounted) context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapErrorToMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editing = widget.group != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Grubu düzenle' : 'Grup oluştur')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      maxLength: GroupLimits.nameMax,
                      textCapitalization: TextCapitalization.words,
                      decoration: AppTheme.inputDecoration(label: 'Grup adı', hint: 'Örn. Elazığ Koşu Grubu'),
                      validator: GroupLimits.name,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showCategoryPicker(context, selectedId: _category);
                        if (picked == null || picked.isEmpty) return;
                        setState(() {
                          _category = picked;
                          _categoryError = null;
                        });
                      },
                      child: InputDecorator(
                        decoration: AppTheme.inputDecoration(label: 'Kategori')
                            .copyWith(suffixIcon: const Icon(Icons.arrow_drop_down)),
                        child: _category == null
                            ? Text('Kategori seç', style: TextStyle(color: theme.hintColor))
                            : Row(children: [
                                Icon(EventCategory.byId(_category!).icon, size: 20),
                                const SizedBox(width: 8),
                                Flexible(child: Text(EventCategory.byId(_category!).label)),
                              ]),
                      ),
                    ),
                    if (_categoryError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 12),
                        child: Text(_categoryError!,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
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
                      controller: _descriptionController,
                      maxLines: 5,
                      maxLength: GroupLimits.descriptionMax,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: AppTheme.inputDecoration(
                        label: 'Açıklama (isteğe bağlı)',
                        hint: 'Grup ne yapar, kimler katılabilir?',
                      ),
                      validator: GroupLimits.description,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(editing ? 'Kaydet' : 'Grubu oluştur'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `/groups/:groupId/edit` yolu: grubu yükleyip formu açar.
class EditGroupScreen extends ConsumerWidget {
  const EditGroupScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId)).valueOrNull;
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Grubu düzenle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return GroupFormScreen(group: group);
  }
}
