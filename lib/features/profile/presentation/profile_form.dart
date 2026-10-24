import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/event_categories.dart';
import '../../../core/constants/turkey_cities.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../data/user_profile.dart';

/// Profil oluşturma ve düzenleme için ortak form.
class ProfileForm extends StatefulWidget {
  const ProfileForm({
    super.key,
    this.initial,
    required this.submitLabel,
    required this.onSubmit,
  });

  final UserProfile? initial;
  final String submitLabel;

  /// Hata fırlatırsa form mesajı gösterir ve düzenlemeye devam ettirir.
  final Future<void> Function(ProfileInput input) onSubmit;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  String? _city;
  late final Set<String> _interests;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.displayName ?? '');
    _bioController = TextEditingController(text: initial?.bio ?? '');
    _city = (initial != null && TurkeyCities.isValid(initial.city))
        ? initial.city
        : null;
    _interests = <String>{
      ...?initial?.interests.where(EventCategory.isValidId),
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        ProfileInput(
          displayName: _nameController.text.trim(),
          city: _city ?? '',
          bio: _bioController.text.trim(),
          interests: _interests.toList(),
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

  void _toggleInterest(String id, bool selected) {
    setState(() {
      if (selected) {
        if (_interests.length >= AppConfig.maxInterests) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'En fazla ${AppConfig.maxInterests} ilgi alanı seçebilirsin.',
              ),
            ),
          );
          return;
        }
        _interests.add(id);
      } else {
        _interests.remove(id);
      }
    });
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
            controller: _nameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            maxLength: AppConfig.displayNameMax,
            decoration: AppTheme.inputDecoration(label: 'Adın'),
            validator: Validators.displayName,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _city,
            isExpanded: true,
            decoration: AppTheme.inputDecoration(label: 'Şehir'),
            items: [
              for (final city in TurkeyCities.all)
                DropdownMenuItem<String>(value: city, child: Text(city)),
            ],
            onChanged: (value) => setState(() => _city = value),
            validator: (value) => value == null ? 'Şehrini seç.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            maxLength: AppConfig.bioMax,
            textCapitalization: TextCapitalization.sentences,
            decoration: AppTheme.inputDecoration(
              label: 'Hakkında',
              hint: 'Kendini kısaca tanıt (isteğe bağlı)',
            ),
            validator: Validators.bio,
          ),
          const SizedBox(height: 16),
          Text('İlgi alanların', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in EventCategory.all)
                FilterChip(
                  avatar: Icon(category.icon, size: 18),
                  label: Text(category.label),
                  selected: _interests.contains(category.id),
                  onSelected: (selected) =>
                      _toggleInterest(category.id, selected),
                ),
            ],
          ),
          const SizedBox(height: 24),
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
