import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/storage/in_memory_key_value_store.dart';
import 'package:gramtransit_passenger/features/saved/data/saved_transit_repository.dart';
import 'package:gramtransit_passenger/features/saved/domain/saved_transit.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';

void main() {
  const savedKey = 'gt.saved.transit';

  final stop1 = StopId('stop_1');
  final stop2 = StopId('stop_2');
  final stop3 = StopId('stop_3');

  final route1 = RouteId('route_1');
  final route2 = RouteId('route_2');

  group('SavedTransitRepository.read', () {
    test('13. missing key returns empty SavedTransit', () {
      final store = InMemoryKeyValueStore();
      final repo = SavedTransitRepository(store);

      final result = repo.read();
      expect(result.stopIds, isEmpty);
      expect(result.routeIds, isEmpty);
    });

    test('14. reads valid version 1 stored payload', () {
      final json = jsonEncode({
        'version': 1,
        'stops': ['stop_1', 'stop_2'],
        'routes': ['route_1'],
      });
      final store = InMemoryKeyValueStore(initial: {savedKey: json});
      final repo = SavedTransitRepository(store);

      final result = repo.read();
      expect(result.stopIds, equals([stop1, stop2]));
      expect(result.routeIds, equals([route1]));
    });

    test('16 & 17. preserves stop and route ordering from storage', () {
      final json = jsonEncode({
        'version': 1,
        'stops': ['stop_3', 'stop_1', 'stop_2'],
        'routes': ['route_2', 'route_1'],
      });
      final store = InMemoryKeyValueStore(initial: {savedKey: json});
      final repo = SavedTransitRepository(store);

      final result = repo.read();
      expect(result.stopIds, equals([stop3, stop1, stop2]));
      expect(result.routeIds, equals([route2, route1]));
    });

    test('18. retains first occurrence for duplicates in storage', () {
      final json = jsonEncode({
        'version': 1,
        'stops': ['stop_1', 'stop_2', 'stop_1'],
        'routes': ['route_1', 'route_2', 'route_1'],
      });
      final store = InMemoryKeyValueStore(initial: {savedKey: json});
      final repo = SavedTransitRepository(store);

      final result = repo.read();
      expect(result.stopIds, equals([stop1, stop2]));
      expect(result.routeIds, equals([route1, route2]));
    });

    test('19, 20 & 21. drops invalid and whitespace-only entries while retaining valid entries', () {
      final json = jsonEncode({
        'version': 1,
        'stops': ['stop_1', 123, '', '   ', 'stop_2'],
        'routes': ['route_1', null, '\t\n', 'route_2'],
      });
      final store = InMemoryKeyValueStore(initial: {savedKey: json});
      final repo = SavedTransitRepository(store);

      final result = repo.read();
      expect(result.stopIds, equals([stop1, stop2]));
      expect(result.routeIds, equals([route1, route2]));
    });

    test(
      '22-30. malformed envelope returns empty SavedTransit without throwing',
      () {
        final malformedCases = [
          '{not valid json}',
          '[1, 2, 3]',
          jsonEncode({
            'stops': ['stop_1'],
            'routes': ['route_1'],
          }), // missing version
          jsonEncode({
            'version': 2,
            'stops': ['stop_1'],
            'routes': ['route_1'],
          }), // unknown version
          jsonEncode({
            'version': '1',
            'stops': ['stop_1'],
            'routes': ['route_1'],
          }), // wrong version type
          jsonEncode({
            'version': 1,
            'routes': ['route_1'],
          }), // missing stops
          jsonEncode({
            'version': 1,
            'stops': ['stop_1'],
          }), // missing routes
          jsonEncode({
            'version': 1,
            'stops': 'stop_1',
            'routes': ['route_1'],
          }), // stops wrong type
          jsonEncode({
            'version': 1,
            'stops': ['stop_1'],
            'routes': 'route_1',
          }), // routes wrong type
        ];

        for (final badJson in malformedCases) {
          final store = InMemoryKeyValueStore(initial: {savedKey: badJson});
          final repo = SavedTransitRepository(store);

          final result = repo.read();
          expect(result.stopIds, isEmpty, reason: 'Failed for: $badJson');
          expect(result.routeIds, isEmpty, reason: 'Failed for: $badJson');
        }
      },
    );

    test('33. malformed/invalid preference reads do not mutate storage', () {
      const originalContent = '{"version": "invalid", "raw": "content"}';
      final store = InMemoryKeyValueStore(initial: {savedKey: originalContent});
      final repo = SavedTransitRepository(store);

      final result = repo.read();
      expect(result.stopIds, isEmpty);
      expect(result.routeIds, isEmpty);
      // Storage must remain unchanged (no write-back on read)
      expect(store.getString(savedKey), equals(originalContent));
    });
  });

  group('SavedTransitRepository.save', () {
    test(
      '14 & 15. persists exact versioned JSON structure to gt.saved.transit',
      () async {
        final store = InMemoryKeyValueStore();
        final repo = SavedTransitRepository(store);

        final saved = SavedTransit(stopIds: [stop1, stop2], routeIds: [route1]);
        await repo.save(saved);

        final storedJson = store.getString(savedKey);
        expect(storedJson, isNotNull);
        expect(
          storedJson,
          equals(
            '{"version":1,"stops":["stop_1","stop_2"],"routes":["route_1"]}',
          ),
        );

        final decoded = jsonDecode(storedJson!) as Map<String, dynamic>;
        expect(decoded['version'], equals(1));
        expect(decoded['stops'], equals(['stop_1', 'stop_2']));
        expect(decoded['routes'], equals(['route_1']));
        expect(decoded.keys, unorderedEquals(['version', 'stops', 'routes']));
      },
    );

    test('14. save then read round-trips correctly', () async {
      final store = InMemoryKeyValueStore();
      final repo = SavedTransitRepository(store);

      final saved = SavedTransit(
        stopIds: [stop3, stop1],
        routeIds: [route2, route1],
      );
      await repo.save(saved);

      final loaded = repo.read();
      expect(loaded.stopIds, equals([stop3, stop1]));
      expect(loaded.routeIds, equals([route2, route1]));
    });

    test(
      '31. empty SavedTransit persists exact valid v1 empty payload',
      () async {
        final store = InMemoryKeyValueStore();
        final repo = SavedTransitRepository(store);

        await repo.save(const SavedTransit.empty());

        final storedJson = store.getString(savedKey);
        expect(storedJson, equals('{"version":1,"stops":[],"routes":[]}'));

        final loaded = repo.read();
        expect(loaded.stopIds, isEmpty);
        expect(loaded.routeIds, isEmpty);
      },
    );

    test('32. StorageFailure from write propagates unchanged', () async {
      final failingStore = const FailingKeyValueStore();
      final repo = SavedTransitRepository(failingStore);

      expect(
        () => repo.save(const SavedTransit.empty()),
        throwsA(isA<StorageFailure>()),
      );
    });
  });
}
