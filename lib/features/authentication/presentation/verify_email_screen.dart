import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../data/auth_repository.dart';
import '../data/session_service.dart';

/// E-posta doğrulama ekranı. Doğrulanana kadar uygulamanın geri kalanına girilemez.
/// Her birkaç saniyede bir doğrulamayı kontrol eder; doğrulanınca router otomatik yönlendirir.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const int _cooldownSeconds = 60;

  Timer? _poll;
  Timer? _cooldown;
  int _secondsLeft = 0;
  bool _checking = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _cooldown?.cancel();
    super.dispose();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _check({bool silent = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final verified = await ref.read(authRepositoryProvider).refreshEmailVerified();
      if (!mounted) return;
      if (verified) {
        // Oturum akışını yeniden başlat: router doğrulanmış kullanıcıyı görür.
        ref.invalidate(authStateProvider);
      } else if (!silent) {
        _toast('E-posta henüz doğrulanmamış. Gelen kutunu ve spam klasörünü kontrol et.');
      }
    } catch (error) {
      if (mounted && !silent) _toast(mapErrorToMessage(error));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (!mounted) return;
      _toast('Doğrulama e-postası gönderildi.');
      setState(() => _secondsLeft = _cooldownSeconds);
      _cooldown?.cancel();
      _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _secondsLeft <= 1) {
          timer.cancel();
          if (mounted) setState(() => _secondsLeft = 0);
          return;
        }
        setState(() => _secondsLeft--);
      });
    } catch (error) {
      if (mounted) _toast(mapErrorToMessage(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = ref.watch(authStateProvider).valueOrNull?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-postanı doğrula'),
        actions: [
          TextButton(
            onPressed: () => ref.read(sessionServiceProvider).signOut(),
            child: const Text('Çıkış yap'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.mark_email_unread_outlined,
                      size: 72, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Doğrulama bağlantısı gönderdik',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'E-postandaki bağlantıya dokun, sonra bu ekrana dön. Mesajı bulamazsan '
                    'spam/gereksiz klasörüne bak.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _checking ? null : () => _check(),
                    child: _checking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Doğruladım'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: (_sending || _secondsLeft > 0) ? null : _resend,
                    child: Text(
                      _secondsLeft > 0
                          ? 'Tekrar gönder ($_secondsLeft sn)'
                          : 'E-postayı tekrar gönder',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Yanlış e-posta mı yazdın? Çıkış yapıp doğru adresle yeniden kayıt ol.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
