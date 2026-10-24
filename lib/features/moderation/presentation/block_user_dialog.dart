import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/block_repository.dart';

/// Onay isteyip kullanıcıyı engeller. Engellendiyse `true` döner.
/// B ve C bunu detay ekranlarındaki menüden çağırır:
/// `await confirmAndBlockUser(context, ref, userId: event.ownerId, userName: event.ownerName)`
Future<bool> confirmAndBlockUser(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String userName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('$userName engellensin mi?'),
      content: const Text(
        'Bu kişinin etkinlikleri sana gösterilmez. '
        'Engellediklerini Ayarlar bölümünden kaldırabilirsin.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          child: const Text('Engelle'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  final user = ref.read(authRepositoryProvider).currentUser;
  if (user == null) return false;
  try {
    await ref
        .read(blockRepositoryProvider)
        .block(uid: user.uid, blockedUid: userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$userName engellendi.')),
      );
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapErrorToMessage(error))),
      );
    }
    return false;
  }
}
