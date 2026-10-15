import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gramtransit_passenger/app/router/app_routes.dart';
import 'package:gramtransit_passenger/app/router/app_shell.dart';
import 'package:gramtransit_passenger/app/router/route_not_found_screen.dart';
import 'package:gramtransit_passenger/features/home/presentation/home_screen.dart';
import 'package:gramtransit_passenger/features/more/presentation/more_screen.dart';
import 'package:gramtransit_passenger/features/settings/presentation/settings_screen.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/trip_details/presentation/trip_details_screen.dart';

// TODO(auth): Guest-first authentication redirect logic will be integrated here
// as a GoRouter [redirect] callback once the authentication domain is introduced.

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Application-wide [GoRouter] provider.
///
/// Created once and not rebuilt on theme or other state changes.
/// The router is disposed when the [ProviderScope] is torn down.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.homePath,
    errorBuilder: (context, state) => const RouteNotFoundScreen(),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Branch 0 — Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homePath,
                name: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1 — More (Settings lives here so NavigationBar stays visible)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.morePath,
                name: AppRoutes.more,
                builder: (context, state) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    name: AppRoutes.settings,
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.tripDetailsPath,
        name: AppRoutes.tripDetails,
        builder: (context, state) {
          final tripIdParam = state.pathParameters['tripId'];
          TripId? tripId;
          if (tripIdParam != null) {
            try {
              tripId = TripId(tripIdParam);
            } on ArgumentError {
              tripId = null;
            }
          }
          return TripDetailsScreen(tripId: tripId);
        },
      ),
    ],
  );

  ref.onDispose(router.dispose);

  return router;
});
