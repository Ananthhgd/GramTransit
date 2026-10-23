import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtransit_passenger/app/router/app_router.dart';
import 'package:gramtransit_passenger/app/router/app_routes.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';

void main() {
  group('parseQueryStopId (Stage 1 Syntactic Parsing)', () {
    test('missing / null raw value returns null', () {
      expect(parseQueryStopId(null), isNull);
    });

    test('empty string returns null', () {
      expect(parseQueryStopId(''), isNull);
    });

    test('whitespace-only string returns null', () {
      expect(parseQueryStopId('   '), isNull);
      expect(parseQueryStopId('\t\n'), isNull);
    });

    test('syntactically valid ID returns StopId with exact value', () {
      final stopId = parseQueryStopId('stop_alpha_1');
      expect(stopId, isNotNull);
      expect(stopId, isA<StopId>());
      expect(stopId!.value, 'stop_alpha_1');
    });

    test('no exceptions escape for arbitrary or malformed input', () {
      expect(parseQueryStopId(''), isNull);
      expect(parseQueryStopId('   '), isNull);
      expect(parseQueryStopId('!@#\$%^&*()'), isNotNull);
      expect(parseQueryStopId('stop with spaces'), isNotNull);
    });
  });

  group('parsePathStopId', () {
    test('missing / null raw value returns null', () {
      expect(parsePathStopId(null), isNull);
    });

    test('empty string returns null', () {
      expect(parsePathStopId(''), isNull);
    });

    test('whitespace-only string returns null', () {
      expect(parsePathStopId('   '), isNull);
      expect(parsePathStopId('\t\n'), isNull);
    });

    test('syntactically valid ID returns StopId with exact value', () {
      final stopId = parsePathStopId('stop_alpha_1');
      expect(stopId, isNotNull);
      expect(stopId, isA<StopId>());
      expect(stopId!.value, 'stop_alpha_1');
    });
  });

  group('parsePathRouteId', () {
    test('missing / null raw value returns null', () {
      expect(parsePathRouteId(null), isNull);
    });

    test('empty string returns null', () {
      expect(parsePathRouteId(''), isNull);
    });

    test('whitespace-only string returns null', () {
      expect(parsePathRouteId('   '), isNull);
      expect(parsePathRouteId('\t\n'), isNull);
    });

    test('syntactically valid ID returns RouteId with exact value', () {
      final routeId = parsePathRouteId('route_alpha_1');
      expect(routeId, isNotNull);
      expect(routeId, isA<RouteId>());
      expect(routeId!.value, 'route_alpha_1');
    });
  });

  group('AppRoutes Constants', () {
    test('journeys route name and path are defined correctly', () {
      expect(AppRoutes.journeys, 'journeys');
      expect(AppRoutes.journeysPath, '/journeys');
    });

    test('browse route names and paths are defined correctly', () {
      expect(AppRoutes.stops, 'stops');
      expect(AppRoutes.stopsPath, '/stops');
      expect(AppRoutes.stopDetails, 'stopDetails');
      expect(AppRoutes.stopDetailsPath, '/stops/:stopId');
      expect(AppRoutes.routes, 'routes');
      expect(AppRoutes.routesPath, '/routes');
      expect(AppRoutes.routeDetails, 'routeDetails');
      expect(AppRoutes.routeDetailsPath, '/routes/:routeId');
    });
  });

  group('Router Route Registration', () {
    test('journeys route is registered as a top-level GoRoute', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      final journeysRoute = router.configuration.routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.name == AppRoutes.journeys);

      expect(journeysRoute.path, AppRoutes.journeysPath);
      expect(journeysRoute.name, AppRoutes.journeys);
    });

    test('browse routes are registered as top-level GoRoutes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      final routes = router.configuration.routes.whereType<GoRoute>().toList();

      final stopsRoute = routes.firstWhere((r) => r.name == AppRoutes.stops);
      expect(stopsRoute.path, AppRoutes.stopsPath);

      final stopDetailsRoute = routes.firstWhere(
        (r) => r.name == AppRoutes.stopDetails,
      );
      expect(stopDetailsRoute.path, AppRoutes.stopDetailsPath);

      final routesRoute = routes.firstWhere((r) => r.name == AppRoutes.routes);
      expect(routesRoute.path, AppRoutes.routesPath);

      final routeDetailsRoute = routes.firstWhere(
        (r) => r.name == AppRoutes.routeDetails,
      );
      expect(routeDetailsRoute.path, AppRoutes.routeDetailsPath);
    });
  });
}
