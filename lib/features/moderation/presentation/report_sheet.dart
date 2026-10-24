import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_theme.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/report_repository.dart';

/// Etkinlik veya kullanıcı şikâyet formunu alt sayfa olarak açar.
/// B ve C bunu detay ekranlarındaki menüden çağırır:
/// `showReportSheet(context, type: ReportTargetType.event, targetId: event.id)`
Future<void> showReportSheet(
  BuildContext context, {
  required ReportTargetType type,
  required String targetId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _ReportSheet(type: type, targetId: targetId),
    ),
  );
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.type, required this.targetId});

  final ReportTargetType type;
  final String targetId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  ReportReason? _reason;
  final _detailsController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) {
        throw const AppException('Oturum bulunamadı. Lütfen tekrar giriş yap.');
      }
      await ref.read(reportRepositoryProvider).submit(
            reporterId: user.uid,
            targetType: widget.type,
            targetId: widget.targetId,
            reason: reason,
            details: _detailsController.text,
          );
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Şikâyetin alındı. Teşekkür ederiz, inceleyeceğiz.'),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(mapErrorToMessage(error))),
      );
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.type == ReportTargetType.event
        ? 'Etkinliği şikâyet et'
        : 'Kullanıcıyı şikâyet et';
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Şikâyetin gizli tutulur, karşı tarafa bildirilmez.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final reason in ReportReason.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _reason == reason
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _reason == reason ? theme.colorScheme.primary : null,
                ),
                title: Text(reason.label),
                onTap: _sending ? null : () => setState(() => _reason = reason),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              maxLength: 500,
              decoration: AppTheme.inputDecoration(
                label: 'Ayrıntı (isteğe bağlı)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: (_reason == null || _sending) ? null : _send,
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gönder'),
            ),
          ],
        ),
      ),
    );
  }
}
