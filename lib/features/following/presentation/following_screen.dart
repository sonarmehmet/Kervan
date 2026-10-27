import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../authentication/data/auth_repository.dart';
import '../../ratings/presentation/rating_widgets.dart';
import '../data/follow_repository.dart';

/// Takip ettiğim düzenleyenler. Yeni etkinlik oluşturduklarında bildirim alırım.
class FollowingScreen extends ConsumerWidget {
  const FollowingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(followingListProvider);
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final list = async.valueOrNull;

    Widget body;
    if (list == null) {
      body = async.hasError
          ? ErrorView(
              message: mapErrorToMessage(async.error!),
              onRetry: () => ref.invalidate(followingListProvider),
            )
          : const LoadingView();
    } else if (list.isEmpty) {
      body = const EmptyView(
        icon: Icons.notifications_none,
        title: 'Kimseyi takip etmiyorsun',
        message: 'Bir etkinliğin detayında "Takip et"e dokunarak düzenleyenleri takip edebilirsin.',
      );
    } else {
      body = ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = list[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(item.organizerName),
            subtitle: RatingBadge(userId: item.organizerId, asOrganizer: true),
            trailing: TextButton(
              onPressed: uid == null
                  ? null
                  : () => ref.read(followRepositoryProvider).unfollow(uid, item.organizerId),
              child: const Text('Takibi bırak'),
            ),
          );
        },
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('Takip ettiklerim')), body: body);
  }
}
