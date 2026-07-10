import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/debug/presentation/design_debug_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/map/presentation/map_screen.dart';
import '../features/modes/presentation/mode_detail_screen.dart';
import '../features/modes/presentation/mode_results_screen.dart';
import '../features/modes/presentation/modes_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/saved/presentation/saved_screen.dart';
import 'navigation_shell.dart';

enum AppRoute {
  root,
  home,
  modes,
  modeDetail,
  modeResults,
  map,
  saved,
  profile,
  dateNight,
  roadTrip,
  designDebug,
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/',
        name: AppRoute.root.name,
        redirect: (context, state) => '/home',
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: AppRoute.home.name,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/modes',
                name: AppRoute.modes.name,
                builder: (context, state) => const ModesScreen(),
                routes: [
                  GoRoute(
                    path: ':modeId',
                    name: AppRoute.modeDetail.name,
                    builder: (context, state) {
                      return ModeDetailScreen(
                        modeId: state.pathParameters['modeId']!,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'results',
                        name: AppRoute.modeResults.name,
                        builder: (context, state) {
                          return ModeResultsScreen(
                            modeId: state.pathParameters['modeId']!,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                name: AppRoute.map.name,
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/saved',
                name: AppRoute.saved.name,
                builder: (context, state) => const SavedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: AppRoute.profile.name,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/date-night',
        name: AppRoute.dateNight.name,
        redirect: (context, state) => '/modes/date-night',
      ),
      GoRoute(
        path: '/road-trip',
        name: AppRoute.roadTrip.name,
        redirect: (context, state) => '/modes/road-trip-stops',
      ),
      GoRoute(
        path: '/debug/design',
        name: AppRoute.designDebug.name,
        builder: (context, state) => const DesignDebugScreen(),
      ),
    ],
  );
});
