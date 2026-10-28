import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../authentication/data/auth_repository.dart';
import '../../authentication/data/session_service.dart';
import '../data/account_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await ref.read(sessionServiceProvider).signOut();
      // Router oturum kapanınca giriş ekranına yönlendirir.
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hesabın silinsin mi?'),
        content: const Text(
          'Profilin, engellediklerin ve bildirimlerin kalıcı olarak silinir. '
          'Oluşturduğun aktif etkinlikler iptal edilir. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 44),
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: const Text('Hesabı sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(accountRepositoryProvider).deleteAccount();
      // Sunucu Auth kaydını sildiği için yerel oturumu da kapat.
      try {
        await ref.read(authRepositoryProvider).signOut();
      } catch (_) {
        // Oturum zaten geçersiz olmuş olabilir; router yine giriş ekranına döner.
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mapErrorToMessage(error))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = ref.watch(authStateProvider).valueOrNull?.email;
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          children: [
            if (email != null)
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('E-posta'),
                subtitle: Text(email),
              ),
            const _ThemeTile(),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Engellenen kullanıcılar'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePaths.blockedUsers),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Takip ettiklerim'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePaths.following),
            ),
            ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: const Text('Kullanım koşulları'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePaths.terms),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Gizlilik politikası'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePaths.privacyPolicy),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Çıkış yap'),
              onTap: _signOut,
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
              title: Text(
                'Hesabı sil',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: _deleteAccount,
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

/// Görünüm: sistem varsayılanı, açık veya koyu tema.
class _ThemeTile extends ConsumerWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return ListTile(
      leading: const Icon(Icons.brightness_6_outlined),
      title: const Text('Görünüm'),
      subtitle: Text(ThemeModeController.label(mode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showDialog<void>(
        context: context,
        builder: (dialogContext) => Consumer(
          builder: (context, ref, _) {
            final current = ref.watch(themeModeProvider);
            return SimpleDialog(
              title: const Text('Görünüm'),
              children: [
                RadioGroup<ThemeMode>(
                  groupValue: current,
                  onChanged: (value) {
                    if (value == null) return;
                    ref.read(themeModeProvider.notifier).setMode(value);
                    Navigator.of(dialogContext).pop();
                  },
                  child: Column(
                    children: [
                      for (final m in ThemeMode.values)
                        RadioListTile<ThemeMode>(
                          value: m,
                          title: Text(ThemeModeController.label(m)),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
