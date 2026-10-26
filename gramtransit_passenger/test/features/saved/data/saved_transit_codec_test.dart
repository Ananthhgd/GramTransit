import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/core/logging/app_logger.dart';
import 'package:gramtransit_passenger/features/saved/data/saved_transit_codec.dart';
import 'package:gramtransit_passenger/features/saved/domain/saved_transit.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';

void main() {
  const logger = AppLogger();
  const codec = SavedTransitCodec(logger: logger);

  final stop1 = StopId('stop_1');
  final stop2 = StopId('stop_2');
  final route1 = RouteId('route_1');
  final route2 = RouteId('route_2');

  group('SavedTransitCodec.decode', () {
    test('13. missing storage value (null) returns empty SavedTransit', () {
      final result = codec.decode(null);
      expect(result.stopIds, isEmpty);
      expect(result.routeIds, isEmpty);
    });

    test('14. valid v1 payload decodes stops and routes in stored order', () {
      final json = jsonEncode({
        'version': 1,
        'stops': ['stop_1', 'stop_2'],
        'routes': ['route_1', 'route_2'],
      });

      final result = codec.decode(json);
      expect(result.stopIds, equals([stop1, stop2]));
      expect(result.routeIds, equals([route1, route2]));
    });

    test('16. stop ordering is preserved during decode', () {
      final json = jsonEncode({
        'version': 1,
        'stops': ['stop_2', 'stop_1'],
        'routes': [],
      });

      final result = codec.decode(json);
      expect(result.stopIds, equals([stop2, stop1]));
    });

    test('17. route ordering is preserved during decode', () {
      final json = jsonEncode({
        'version': 1,
        'stops': [],
        'routes': ['route_2', 'route_1'],
      });

      final result = codec.decode(json);
      expect(result.routeIds, equals([route2, route1]));
    });

    test('18. duplicates retain first occurrence only', () {
      final json = jsonEncode({
        'version': 1,
        'stops': ['stop_1', 'stop_2', 'stop_1'],
        'routes': ['route_1', 'route_2', 'route_1'],
      });

      final result = codec.decode(json);
      expect(result.stopIds, equals([stop1, stop2]));
      expect(result.routeIds, equals([route1, route2]));
    });

    test(
      '19. invalid individual stop entry dropped while valid entries survive',
      () {
        final json = jsonEncode({
          'version': 1,
          'stops': [
            'stop_1',
            123,
            null,
            true,
            {'id': 'stop_x'},
            ['nested'],
            'stop_2',
          ],
          'routes': ['route_1'],
        });

        final result = codec.decode(json);
        expect(result.stopIds, equals([stop1, stop2]));
        expect(result.routeIds, equals([route1]));
      },
    );

    test(
      '20. invalid individual route entry dropped while valid entries survive',
      () {
        final json = jsonEncode({
          'version': 1,
          'stops': ['stop_1'],
          'routes': [
            'route_1',
            456,
            null,
            false,
            {'route': 'bad'},
            'route_2',
          ],
        });

        final result = codec.decode(json);
        expect(result.stopIds, equals([stop1]));
        expect(result.routeIds, equals([route1, route2]));
      },
    );

    test('21. whitespace-only and empty IDs are dropped', () {
      final json = jsonEncode({
        'version': 1,
        'stops': ['', '   ', 'stop_1', '\t\n'],
        'routes': ['\r', 'route_1', '     '],
      });

      final result = codec.decode(json);
      expect(result.stopIds, equals([stop1]));
      expect(result.routeIds, equals([route1]));
    });

    test('22. malformed JSON returns empty SavedTransit without throwing', () {
      const malformedJson = '{"version": 1, "stops": [unquoted]}';
      final result = codec.decode(malformedJson);
      expect(result.stopIds, isEmpty);
      expect(result.routeIds, isEmpty);
    });

    test('23. top-level non-object returns empty SavedTransit', () {
      expect(codec.decode('[1, 2, 3]').stopIds, isEmpty);
      expect(codec.decode('"just a string"').stopIds, isEmpty);
      expect(codec.decode('12345').stopIds, isEmpty);
      expect(codec.decode('true').stopIds, isEmpty);
    });

    test('24. missing version field returns empty SavedTransit', () {
      final json = jsonEncode({
        'stops': ['stop_1'],
        'routes': ['route_1'],
      });

      final result = codec.decode(json);
      expect(result.stopIds, isEmpty);
      expect(result.routeIds, isEmpty);
    });

    test('25. unknown version returns empty SavedTransit', () {
      final jsonV2 = jsonEncode({
        'version': 2,
        'stops': ['stop_1'],
        'routes': ['route_1'],
      });
      final jsonV0 = jsonEncode({
        'version': 0,
        'stops': ['stop_1'],
        'routes': ['route_1'],
      });

      expect(codec.decode(jsonV2).stopIds, isEmpty);
      expect(codec.decode(jsonV0).stopIds, isEmpty);
    });

    test('26. wrong version type returns empty SavedTransit', () {
      final jsonStringVersion = jsonEncode({
        'version': '1',
        'stops': ['stop_1'],
        'routes': ['route_1'],
      });
      final jsonDoubleVersion = jsonEncode({
        'version': 1.5,
        'stops': ['stop_1'],
        'routes': ['route_1'],
      });

      expect(codec.decode(jsonStringVersion).stopIds, isEmpty);
      expect(codec.decode(jsonDoubleVersion).stopIds, isEmpty);
    });

    test('27. missing stops list returns empty SavedTransit', () {
      final json = jsonEncode({
        'version': 1,
        'routes': ['route_1'],
      });

      final result = codec.decode(json);
      expect(result.stopIds, isEmpty);
      expect(result.routeIds, isEmpty);
    });

    test('28. missing routes list returns empty SavedTransit', () {
      final json = jsonEncode({
        'version': 1,
        'stops': ['stop_1'],
      });

      final result = codec.decode(json);
      expect(result.stopIds, isEmpty);
      expect(result.routeIds, isEmpty);
    });

    test('29. stops of wrong type returns empty SavedTransit', () {
      final jsonStringStops = jsonEncode({
        'version': 1,
        'stops': 'stop_1',
        'routes': ['route_1'],
      });
      final jsonMapStops = jsonEncode({
        'version': 1,
        'stops': {'id': 'stop_1'},
        'routes': ['route_1'],
      });

      expect(codec.decode(jsonStringStops).stopIds, isEmpty);
      expect(codec.decode(jsonMapStops).stopIds, isEmpty);
    });

    test('30. routes of wrong type returns empty SavedTransit', () {
      final jsonStringRoutes = jsonEncode({
        'version': 1,
        'stops': ['stop_1'],
        'routes': 'route_1',
      });
      final jsonIntRoutes = jsonEncode({
        'version': 1,
        'stops': ['stop_1'],
        'routes': 42,
      });

      expect(codec.decode(jsonStringRoutes).routeIds, isEmpty);
      expect(codec.decode(jsonIntRoutes).routeIds, isEmpty);
    });
  });

  group('SavedTransitCodec.encode', () {
    test('15. exact versioned JSON structure with valid data', () {
      final saved = SavedTransit(stopIds: [stop1], routeIds: [route1]);

      final encoded = codec.encode(saved);
      expect(
        encoded,
        equals('{"version":1,"stops":["stop_1"],"routes":["route_1"]}'),
      );

      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['version'], equals(1));
      expect(decoded['stops'], equals(['stop_1']));
      expect(decoded['routes'], equals(['route_1']));
      expect(decoded.keys, unorderedEquals(['version', 'stops', 'routes']));
    });

    test('31. empty SavedTransit persists exact valid v1 empty payload', () {
      const empty = SavedTransit.empty();
      final encoded = codec.encode(empty);

      expect(encoded, equals('{"version":1,"stops":[],"routes":[]}'));

      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['version'], equals(1));
      expect(decoded['stops'], isEmpty);
      expect(decoded['routes'], isEmpty);
    });
  });
}
