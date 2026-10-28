import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/saved_repository.dart';

/// Etkinliği kaydet / kaydı kaldır (yer imi simgesi).
class SaveButton extends ConsumerStatefulWidget {
  const SaveButton({super.key, required this.eventId, this.filled = false});

  final String eventId;

  /// `true` ise görsel üstünde okunması için dolgulu yuvarlak zeminle çizilir.
  final bool filled;

  @override
  ConsumerState<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends ConsumerState<SaveButton> {
  bool _busy = false;

  Future<void> _toggle(String uid, bool saved) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(savedRepositoryProvider);
      if (saved) {
        await repo.unsave(uid, widget.eventId);
      } else {
        await repo.save(uid, widget.eventId);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapErrorToMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    if (uid == null) return const SizedBox.shrink();
    final saved = ref.watch(isSavedProvider(widget.eventId));
    final icon = Icon(saved ? Icons.bookmark : Icons.bookmark_border);
    final tooltip = saved ? 'Kaydedilenlerden çıkar' : 'Kaydet';
    final onPressed = _busy ? null : () => _toggle(uid, saved);
    if (widget.filled) {
      return IconButton.filledTonal(tooltip: tooltip, onPressed: onPressed, icon: icon);
    }
    return IconButton(tooltip: tooltip, onPressed: onPressed, icon: icon);
  }
}
