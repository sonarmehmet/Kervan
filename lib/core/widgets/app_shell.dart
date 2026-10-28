import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/data/notification_repository.dart';
import '../router/route_names.dart';
import '../theme/rota_colors.dart';

/// Alt gezinme çubuğu olan ana kabuk. Sıra, router'daki branch sırasıyla aynıdır:
/// 0 Keşfet, 1 Etkinliklerim, 2 Bildirimler, 3 Profil.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _slotOf(navigationShell.currentIndex),
        onDestinationSelected: (slot) {
          if (slot == 2) {
            context.push(RoutePaths.createEvent);
            return;
          }
          final branch = slot < 2 ? slot : slot - 1;
          navigationShell.goBranch(
            branch,
            initialLocation: branch == navigationShell.currentIndex,
          );
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Keşfet',
          ),
          const NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Etkinliklerim',
          ),
          const NavigationDestination(
            icon: _CreateIcon(),
            selectedIcon: _CreateIcon(),
            label: 'Oluştur',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Bildirimler',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Branch sırasını (4 hedef) çubuk sırasına (ortada "+" ile 5 yuva) çevirir.
int _slotOf(int branch) => branch < 2 ? branch : branch + 1;

class _CreateIcon extends StatelessWidget {
  const _CreateIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: RotaColors.sun,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add, color: RotaColors.ink, size: 28),
    );
  }
}
