import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/event_categories.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../data/profile_repository.dart';
import '../data/user_profile.dart';

/// Giriş yapmış kullanıcının kendi profili (alt gezinme "Profil" sekmesi).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: mapErrorToMessage(error),
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (value) {
          if (value == null) return const LoadingView();
          return _ProfileContent(profile: value);
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = profile.displayName.isEmpty
        ? '?'
        : profile.displayName.characters.first.toUpperCase();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              initial,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.displayName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        if (profile.city.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                profile.city,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(profile.bio, textAlign: TextAlign.center),
        ],
        if (profile.interests.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('İlgi alanları', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in profile.interests)
                Chip(
                  avatar: Icon(EventCategory.byId(id).icon, size: 18),
                  label: Text(EventCategory.byId(id).label),
                ),
            ],
          ),
        ],
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: () => context.push(RoutePaths.editProfile),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Profili düzenle'),
        ),
      ],
    );
  }
}
