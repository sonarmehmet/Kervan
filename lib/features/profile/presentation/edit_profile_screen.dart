import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/profile_repository.dart';
import '../data/user_profile.dart';
import 'profile_form.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    ProfileInput input,
  ) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      throw const AppException('Oturum bulunamadı. Lütfen tekrar giriş yap.');
    }
    await ref.read(profileRepositoryProvider).updateProfile(user.uid, input);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profilin güncellendi.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profili düzenle')),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: mapErrorToMessage(error),
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (value) => SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ProfileForm(
                  initial: value,
                  submitLabel: 'Kaydet',
                  onSubmit: (input) => _update(context, ref, input),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
