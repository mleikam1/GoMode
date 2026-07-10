import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/debug/presentation/design_debug_screen.dart';
import '../features/date_night/data/date_night_planning_service.dart';
import '../features/date_night/domain/date_night_preferences.dart';
import '../features/date_night/domain/generated_plan.dart';
import '../features/date_night/presentation/date_night_plan_screen.dart';
import '../features/date_night/presentation/date_night_setup_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/map/presentation/map_screen.dart';
import '../features/modes/presentation/mode_detail_screen.dart';
import '../features/modes/presentation/mode_results_screen.dart';
import '../features/modes/presentation/modes_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/legal_screen.dart';
import '../features/road_trip/presentation/road_trip_stops_screen.dart';
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
  dateNightPlan,
  roadTrip,
  designDebug,
  privacy,
  terms,
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
                    path: 'date-night',
                    name: AppRoute.dateNight.name,
                    pageBuilder: (context, state) =>
                        _motionPage(state, const DateNightSetupScreen()),
                    routes: [
                      GoRoute(
                        path: 'plan',
                        name: AppRoute.dateNightPlan.name,
                        pageBuilder: (context, state) {
                          final plan = state.extra is GeneratedPlan
                              ? state.extra! as GeneratedPlan
                              : generateDemoDateNightPlan(
                                  const DateNightPreferences.defaults(),
                                );
                          return _motionPage(
                            state,
                            DateNightPlanScreen(plan: plan),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'road-trip-stops',
                    name: AppRoute.roadTrip.name,
                    pageBuilder: (context, state) =>
                        _motionPage(state, const RoadTripStopsScreen()),
                    routes: [
                      GoRoute(
                        path: 'results',
                        redirect: (context, state) => '/modes/road-trip-stops',
                      ),
                    ],
                  ),
                  GoRoute(
                    path: ':modeId',
                    name: AppRoute.modeDetail.name,
                    pageBuilder: (context, state) {
                      return _motionPage(
                        state,
                        ModeDetailScreen(
                          modeId: state.pathParameters['modeId']!,
                        ),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'results',
                        name: AppRoute.modeResults.name,
                        pageBuilder: (context, state) {
                          return _motionPage(
                            state,
                            ModeResultsScreen(
                              modeId: state.pathParameters['modeId']!,
                              selectedFilters: state.uri.queryParameters,
                            ),
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
        redirect: (context, state) => '/modes/date-night',
      ),
      GoRoute(
        path: '/road-trip',
        redirect: (context, state) => '/modes/road-trip-stops',
      ),
      GoRoute(
        path: '/debug/design',
        name: AppRoute.designDebug.name,
        pageBuilder: (context, state) =>
            _motionPage(state, const DesignDebugScreen()),
      ),
      GoRoute(
        path: '/privacy',
        name: AppRoute.privacy.name,
        pageBuilder: (context, state) =>
            _motionPage(state, const PrivacyScreen()),
      ),
      GoRoute(
        path: '/terms',
        name: AppRoute.terms.name,
        pageBuilder: (context, state) =>
            _motionPage(state, const TermsScreen()),
      ),
    ],
  );
});

Page<void> _motionPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return child;
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: Tween<double>(begin: 0.86, end: 1).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.035, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
