import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/router/route_names.dart';
import '../../authentication/data/auth_repository.dart';
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
      await ref.read(authRepositoryProvider).signOut();
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
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Engellenen kullanıcılar'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePaths.blockedUsers),
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
