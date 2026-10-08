import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gramtransit_passenger/app/router/app_routes.dart';
import 'package:gramtransit_passenger/app/router/app_shell.dart';
import 'package:gramtransit_passenger/app/router/route_not_found_screen.dart';
import 'package:gramtransit_passenger/features/home/presentation/home_screen.dart';
import 'package:gramtransit_passenger/features/more/presentation/more_screen.dart';
import 'package:gramtransit_passenger/features/settings/presentation/settings_screen.dart';

// TODO(auth): Guest-first authentication redirect logic will be integrated here
// as a GoRouter [redirect] callback once the authentication domain is introduced.

/// Application-wide [GoRouter] provider.
///
/// Created once and not rebuilt on theme or other state changes.
/// The router is disposed when the [ProviderScope] is torn down.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
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
    ],
  );

  ref.onDispose(router.dispose);

  return router;
});
