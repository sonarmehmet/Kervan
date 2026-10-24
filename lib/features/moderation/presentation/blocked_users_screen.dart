import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../data/block_repository.dart';

/// Engellenen kullanıcının görünen adı. Profil bulunamazsa genel bir ad döner.
final _blockedNameProvider = FutureProvider.family<String, String>((ref, uid) async {
  final profile = await ref.watch(profileRepositoryProvider).getProfile(uid);
  final name = profile?.displayName ?? '';
  return name.isEmpty ? 'Kullanıcı' : name;
});

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  Future<void> _unblock(BuildContext context, WidgetRef ref, String uid) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    try {
      await ref
          .read(blockRepositoryProvider)
          .unblock(uid: user.uid, blockedUid: uid);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapErrorToMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedUserIdsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Engellenen kullanıcılar')),
      body: blocked.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: mapErrorToMessage(error),
          onRetry: () => ref.invalidate(blockedUserIdsProvider),
        ),
        data: (ids) {
          if (ids.isEmpty) {
            return const EmptyView(
              icon: Icons.block,
              title: 'Kimseyi engellemedin',
              message: 'Engellediğin kişiler burada görünür.',
            );
          }
          final sorted = ids.toList()..sort();
          return ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final uid = sorted[index];
              final name = ref.watch(_blockedNameProvider(uid));
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_off)),
                title: Text(name.valueOrNull ?? '...'),
                trailing: TextButton(
                  onPressed: () => _unblock(context, ref, uid),
                  child: const Text('Engeli kaldır'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
