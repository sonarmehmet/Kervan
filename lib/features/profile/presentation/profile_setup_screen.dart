import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/profile_repository.dart';
import '../data/user_profile.dart';
import 'profile_form.dart';

/// Kayıttan sonra ilk profil oluşturma ekranı.
/// Profil kaydedilince router kullanıcıyı otomatik olarak ana ekrana yönlendirir.
class ProfileSetupScreen extends ConsumerWidget {
  const ProfileSetupScreen({super.key});

  Future<void> _create(WidgetRef ref, ProfileInput input) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      throw const AppException('Oturum bulunamadı. Lütfen tekrar giriş yap.');
    }
    await ref.read(profileRepositoryProvider).createProfile(user.uid, input);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilini oluştur'),
        actions: [
          TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('Çıkış yap'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ProfileForm(
                submitLabel: 'Devam et',
                onSubmit: (input) => _create(ref, input),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
