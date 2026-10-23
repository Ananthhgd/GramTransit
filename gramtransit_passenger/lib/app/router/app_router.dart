import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gramtransit_passenger/app/router/app_routes.dart';
import 'package:gramtransit_passenger/app/router/app_shell.dart';
import 'package:gramtransit_passenger/app/router/route_not_found_screen.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_empty_state.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/browse/presentation/route_details_screen.dart';
import 'package:gramtransit_passenger/features/browse/presentation/routes_screen.dart';
import 'package:gramtransit_passenger/features/browse/presentation/stop_details_screen.dart';
import 'package:gramtransit_passenger/features/browse/presentation/stops_screen.dart';
import 'package:gramtransit_passenger/features/home/presentation/home_screen.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/journey_search_screen.dart';
import 'package:gramtransit_passenger/features/more/presentation/more_screen.dart';
import 'package:gramtransit_passenger/features/settings/presentation/settings_screen.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/trip_details/presentation/trip_details_screen.dart';

// TODO(auth): Guest-first authentication redirect logic will be integrated here
// as a GoRouter [redirect] callback once the authentication domain is introduced.

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Parses an optional route query parameter into a [StopId].
///
/// Returns `null` if [raw] is absent, empty, or fails [StopId] syntax validation.
/// Does not perform timetable lookups or throw exceptions.
@visibleForTesting
StopId? parseQueryStopId(String? raw) {
  if (raw == null) return null;
  try {
    return StopId(raw);
  } on ArgumentError {
    return null;
  }
}

/// Parses a route path parameter into a [StopId].
///
/// Returns `null` if [raw] is absent, empty, or fails [StopId] syntax validation.
/// Does not perform timetable lookups or throw exceptions.
@visibleForTesting
StopId? parsePathStopId(String? raw) {
  if (raw == null) return null;
  try {
    return StopId(raw);
  } on ArgumentError {
    return null;
  }
}

/// Parses a route path parameter into a [RouteId].
///
/// Returns `null` if [raw] is absent, empty, or fails [RouteId] syntax validation.
/// Does not perform timetable lookups or throw exceptions.
@visibleForTesting
RouteId? parsePathRouteId(String? raw) {
  if (raw == null) return null;
  try {
    return RouteId(raw);
  } on ArgumentError {
    return null;
  }
}

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
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.journeysPath,
        name: AppRoutes.journeys,
        builder: (context, state) {
          final fromParam = state.uri.queryParameters['from'];
          final toParam = state.uri.queryParameters['to'];

          return JourneySearchScreen(
            initialBoardingStopId: parseQueryStopId(fromParam),
            initialAlightingStopId: parseQueryStopId(toParam),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.stopsPath,
        name: AppRoutes.stops,
        builder: (context, state) => StopsScreen(
          onStopTap: (stopId) {
            context.pushNamed(
              AppRoutes.stopDetails,
              pathParameters: {'stopId': stopId.value},
            );
          },
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.stopDetailsPath,
        name: AppRoutes.stopDetails,
        builder: (context, state) {
          final stopId = parsePathStopId(state.pathParameters['stopId']);
          if (stopId == null) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.stopDetailsTitle)),
              body: SafeArea(
                child: GtEmptyState(
                  icon: Icons.place_outlined,
                  title: context.l10n.stopNotFoundTitle,
                  message: context.l10n.stopNotFoundMessage,
                  actionLabel: context.l10n.stopNotFoundAction,
                  onAction: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.goNamed(AppRoutes.home);
                    }
                  },
                ),
              ),
            );
          }
          return StopDetailsScreen(
            stopId: stopId,
            onPlanJourney: (id) {
              context.pushNamed(
                AppRoutes.journeys,
                queryParameters: {'from': id.value},
              );
            },
            onTripTap: (tripId) {
              context.pushNamed(
                AppRoutes.tripDetails,
                pathParameters: {'tripId': tripId.value},
              );
            },
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(AppRoutes.home);
              }
            },
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.routesPath,
        name: AppRoutes.routes,
        builder: (context, state) => RoutesScreen(
          onRouteTap: (routeId) {
            context.pushNamed(
              AppRoutes.routeDetails,
              pathParameters: {'routeId': routeId.value},
            );
          },
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.routeDetailsPath,
        name: AppRoutes.routeDetails,
        builder: (context, state) {
          final routeId = parsePathRouteId(state.pathParameters['routeId']);
          if (routeId == null) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.routeDetailsTitle)),
              body: SafeArea(
                child: GtEmptyState(
                  icon: Icons.alt_route_rounded,
                  title: context.l10n.routeNotFoundTitle,
                  message: context.l10n.routeNotFoundMessage,
                  actionLabel: context.l10n.routeNotFoundAction,
                  onAction: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.goNamed(AppRoutes.home);
                    }
                  },
                ),
              ),
            );
          }
          return RouteDetailsScreen(
            routeId: routeId,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(AppRoutes.home);
              }
            },
            onTripTap: (tripId) {
              context.pushNamed(
                AppRoutes.tripDetails,
                pathParameters: {'tripId': tripId.value},
              );
            },
          );
        },
      ),
    ],
  );

  ref.onDispose(router.dispose);

  return router;
});
