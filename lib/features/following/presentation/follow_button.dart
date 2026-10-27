import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/follow_repository.dart';

/// Düzenleyeni takip et / takibi bırak. Kendi etkinliğinde görünmez.
class FollowButton extends ConsumerStatefulWidget {
  const FollowButton({
    super.key,
    required this.organizerId,
    required this.organizerName,
  });

  final String organizerId;
  final String organizerName;

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool _busy = false;

  Future<void> _toggle(String uid, bool following) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(followRepositoryProvider);
      if (following) {
        await repo.unfollow(uid, widget.organizerId);
      } else {
        await repo.follow(
          uid: uid,
          organizerId: widget.organizerId,
          organizerName: widget.organizerName,
        );
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
    if (uid == null || uid == widget.organizerId) return const SizedBox.shrink();
    final following = ref.watch(isFollowingProvider(widget.organizerId));
    return TextButton.icon(
      onPressed: _busy ? null : () => _toggle(uid, following),
      icon: Icon(following ? Icons.notifications_active : Icons.notifications_none, size: 18),
      label: Text(following ? 'Takip ediliyor' : 'Takip et'),
    );
  }
}
