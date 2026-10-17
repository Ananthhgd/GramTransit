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

  group('AppRoutes Constants', () {
    test('journeys route name and path are defined correctly', () {
      expect(AppRoutes.journeys, 'journeys');
      expect(AppRoutes.journeysPath, '/journeys');
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
  });
}
