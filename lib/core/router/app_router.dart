import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/data/auth_repository.dart';
import '../../features/authentication/presentation/forgot_password_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
import '../../features/authentication/presentation/splash_screen.dart';
import '../../features/event_creation/presentation/create_event_screen.dart';
import '../../features/event_creation/presentation/edit_event_screen.dart';
import '../../features/event_details/presentation/event_details_screen.dart';
import '../../features/event_details/presentation/my_events_screen.dart';
import '../../features/event_discovery/presentation/discover_screen.dart';
import '../../features/moderation/presentation/blocked_users_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/participation/presentation/participants_screen.dart';
import '../../features/participation/presentation/request_list_screen.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import '../../features/settings/presentation/privacy_policy_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../widgets/app_shell.dart';
import 'route_names.dart';

/// Uygulamanın tek GoRouter'ı.
///
/// Yönlendirme kuralları (redirect):
///  1. Oturum/profil yükleniyor veya hatalı  -> splash
///  2. Giriş yok                              -> login (herkese açık yollar hariç)
///  3. Giriş var, profil yok                  -> profile-setup
///  4. Giriş ve profil var, giriş/kurulum yolundaysa -> discover
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => refresh.value++);
  ref.listen(currentProfileProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  String? redirect(String location) {
    final auth = ref.read(authStateProvider);
    if (auth.isLoading || auth.hasError) {
      return location == RoutePaths.splash ? null : RoutePaths.splash;
    }

    final user = auth.valueOrNull;
    if (user == null) {
      return RoutePaths.publicPaths.contains(location) ? null : RoutePaths.login;
    }

    final profile = ref.read(currentProfileProvider);
    if (profile.isLoading || profile.hasError) {
      return location == RoutePaths.splash ? null : RoutePaths.splash;
    }

    final hasProfile = profile.valueOrNull != null;
    if (!hasProfile) {
      return location == RoutePaths.profileSetup ? null : RoutePaths.profileSetup;
    }

    const entryPaths = <String>{
      RoutePaths.splash,
      RoutePaths.login,
      RoutePaths.register,
      RoutePaths.forgotPassword,
      RoutePaths.profileSetup,
    };
    if (entryPaths.contains(location)) return RoutePaths.discover;
    return null;
  }

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refresh,
    redirect: (context, state) => redirect(state.matchedLocation),
    routes: <RouteBase>[
      // --- Oturum ve kurulum (A) ---
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // --- Profil ve ayarlar (A) ---
      GoRoute(
        path: RoutePaths.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.blockedUsers,
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: RoutePaths.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      // --- Etkinlikler --- sabit yollar ':eventId' değişkeninden önce gelir.
      GoRoute(
        path: RoutePaths.createEvent,
        builder: (context, state) => const CreateEventScreen(),
      ),
      GoRoute(
        path: '/events/:eventId',
        builder: (context, state) => EventDetailsScreen(
          eventId: state.pathParameters['eventId']!,
        ),
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            builder: (context, state) => EditEventScreen(
              eventId: state.pathParameters['eventId']!,
            ),
          ),
          GoRoute(
            path: 'requests',
            builder: (context, state) => RequestListScreen(
              eventId: state.pathParameters['eventId']!,
            ),
          ),
          GoRoute(
            path: 'chat',
            builder: (context, state) => ChatScreen(
              eventId: state.pathParameters['eventId']!,
            ),
          ),
          GoRoute(
            path: 'participants',
            builder: (context, state) => ParticipantsScreen(
              eventId: state.pathParameters['eventId']!,
            ),
          ),
        ],
      ),

      // --- Alt gezinme kabuğu ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.discover,
                builder: (context, state) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.myEvents,
                builder: (context, state) => const MyEventsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.notifications,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
