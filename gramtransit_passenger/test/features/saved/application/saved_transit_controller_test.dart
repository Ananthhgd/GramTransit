import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/storage/in_memory_key_value_store.dart';
import 'package:gramtransit_passenger/core/storage/key_value_store.dart';
import 'package:gramtransit_passenger/core/storage/storage_providers.dart';
import 'package:gramtransit_passenger/features/saved/application/saved_transit_controller.dart';
import 'package:gramtransit_passenger/features/saved/application/saved_transit_providers.dart';
import 'package:gramtransit_passenger/features/saved/data/saved_transit_repository.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';

/// Test spy for [KeyValueStore] that records write operations.
final class SpyKeyValueStore implements KeyValueStore {
  SpyKeyValueStore({Map<String, String>? initial})
    : _store = initial != null ? Map.of(initial) : {};

  final Map<String, String> _store;
  int writeCount = 0;

  @override
  String? getString(String key) => _store[key];

  @override
  Future<void> setString(String key, String value) async {
    writeCount++;
    _store[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }
}

/// Test double that permits reading but simulates a storage write failure.
final class FailingWriteKeyValueStore implements KeyValueStore {
  FailingWriteKeyValueStore({
    Map<String, String>? initial,
    this.failureCause = 'Simulated write failure',
  }) : _store = initial != null ? Map.of(initial) : {};

  final Map<String, String> _store;
  final Object failureCause;

  @override
  String? getString(String key) => _store[key];

  @override
  Future<void> setString(String key, String value) async {
    throw StorageFailure(cause: failureCause);
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }
}

ProviderContainer makeContainer({required KeyValueStore store}) {
  return ProviderContainer(
    overrides: [keyValueStoreProvider.overrideWithValue(store)],
  );
}

void main() {
  const savedKey = 'gt.saved.transit';

  final stop1 = StopId('stop_1');
  final stop2 = StopId('stop_2');
  final stop3 = StopId('stop_3');

  final route1 = RouteId('route_1');
  final route2 = RouteId('route_2');
  final route3 = RouteId('route_3');

  group('SavedTransitController — Initialization', () {
    test('1. controller initializes from an empty repository/store state', () {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store: store);
      addTearDown(container.dispose);

      final state = container.read(savedTransitControllerProvider);
      expect(state.stopIds, isEmpty);
      expect(state.routeIds, isEmpty);
    });

    test('2. controller initializes from persisted saved stops/routes', () {
      final storedJson = jsonEncode({
        'version': 1,
        'stops': ['stop_1', 'stop_2'],
        'routes': ['route_1'],
      });
      final store = InMemoryKeyValueStore(initial: {savedKey: storedJson});
      final container = makeContainer(store: store);
      addTearDown(container.dispose);

      final state = container.read(savedTransitControllerProvider);
      expect(state.stopIds, equals([stop1, stop2]));
      expect(state.routeIds, equals([route1]));
    });

    test(
      'initializes with empty SavedTransit when persisted content is malformed',
      () {
        final store = InMemoryKeyValueStore(
          initial: {savedKey: '{not valid json}'},
        );
        final container = makeContainer(store: store);
        addTearDown(container.dispose);

        final state = container.read(savedTransitControllerProvider);
        expect(state.stopIds, isEmpty);
        expect(state.routeIds, isEmpty);
      },
    );
  });

  group('SavedTransitController — saveStop & unsaveStop', () {
    test('3. saveStop updates state and persists updated state', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store: store);
      addTearDown(container.dispose);

      await container
          .read(savedTransitControllerProvider.notifier)
          .saveStop(stop1);

      final state = container.read(savedTransitControllerProvider);
      expect(state.stopIds, equals([stop1]));
      expect(state.containsStop(stop1), isTrue);

      final rawStored = store.getString(savedKey);
      expect(rawStored, isNotNull);
      final decoded = jsonDecode(rawStored!) as Map<String, dynamic>;
      expect(decoded['version'], equals(1));
      expect(decoded['stops'], equals(['stop_1']));
      expect(decoded['routes'], isEmpty);
    });

    test('4. unsaveStop updates state and persists updated state', () async {
      final storedJson = jsonEncode({
        'version': 1,
        'stops': ['stop_1', 'stop_2'],
        'routes': ['route_1'],
      });
      final store = InMemoryKeyValueStore(initial: {savedKey: storedJson});
      final container = makeContainer(store: store);
      addTearDown(container.dispose);

      await container
          .read(savedTransitControllerProvider.notifier)
          .unsaveStop(stop1);

      final state = container.read(savedTransitControllerProvider);
      expect(state.stopIds, equals([stop2]));
      expect(state.containsStop(stop1), isFalse);
      expect(state.containsStop(stop2), isTrue);

      final rawStored = store.getString(savedKey);
      final decoded = jsonDecode(rawStored!) as Map<String, dynamic>;
      expect(decoded['stops'], equals(['stop_2']));
    });
  });

  group('SavedTransitController — saveRoute & unsaveRoute', () {
    test('5. saveRoute updates state and persists updated state', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store: store);
      addTearDown(container.dispose);

      await container
          .read(savedTransitControllerProvider.notifier)
          .saveRoute(route1);

      final state = container.read(savedTransitControllerProvider);
      expect(state.routeIds, equals([route1]));
      expect(state.containsRoute(route1), isTrue);

      final rawStored = store.getString(savedKey);
      expect(rawStored, isNotNull);
      final decoded = jsonDecode(rawStored!) as Map<String, dynamic>;
      expect(decoded['version'], equals(1));
      expect(decoded['routes'], equals(['route_1']));
      expect(decoded['stops'], isEmpty);
    });

    test('6. unsaveRoute updates state and persists updated state', () async {
      final storedJson = jsonEncode({
        'version': 1,
        'stops': ['stop_1'],
        'routes': ['route_1', 'route_2'],
      });
      final store = InMemoryKeyValueStore(initial: {savedKey: storedJson});
      final container = makeContainer(store: store);
      addTearDown(container.dispose);

      await container
          .read(savedTransitControllerProvider.notifier)
          .unsaveRoute(route1);

      final state = container.read(savedTransitControllerProvider);
      expect(state.routeIds, equals([route2]));
      expect(state.containsRoute(route1), isFalse);
      expect(state.containsRoute(route2), isTrue);

      final rawStored = store.getString(savedKey);
      final decoded = jsonDecode(rawStored!) as Map<String, dynamic>;
      expect(decoded['routes'], equals(['route_2']));
    });
  });

  group('SavedTransitController — State Independence & Ordering', () {
    test('7. stop and route state remain independent', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store: store);
      addTearDown(container.dispose);

      final controller = container.read(
        savedTransitControllerProvider.notifier,
      );

      await controller.saveStop(stop1);
      expect(
        container.read(savedTransitControllerProvider).stopIds,
        equals([stop1]),
      );
      expect(container.read(savedTransitControllerProvider).routeIds, isEmpty);

      await controller.saveRoute(route1);
      expect(
        container.read(savedTransitControllerProvider).stopIds,
        equals([stop1]),
      );
      expect(
        container.read(savedTransitControllerProvider).routeIds,
        equals([route1]),
      );

      await controller.unsaveStop(stop1);
      expect(container.read(savedTransitControllerProvider).stopIds, isEmpty);
      expect(
        container.read(savedTransitControllerProvider).routeIds,
        equals([route1]),
      );

      await controller.unsaveRoute(route1);
      expect(container.read(savedTransitControllerProvider).stopIds, isEmpty);
      expect(container.read(savedTransitControllerProvider).routeIds, isEmpty);
    });

    test(
      '8. save order remains correct through controller mutations',
      () async {
        final store = InMemoryKeyValueStore();
        final container = makeContainer(store: store);
        addTearDown(container.dispose);

        final controller = container.read(
          savedTransitControllerProvider.notifier,
        );

        await controller.saveStop(stop1);
        await controller.saveStop(stop2);
        await controller.saveStop(stop3);

        expect(
          container.read(savedTransitControllerProvider).stopIds,
          equals([stop1, stop2, stop3]),
        );

        // Remove stop2, then save stop2 again -> appended at end
        await controller.unsaveStop(stop2);
        await controller.saveStop(stop2);

        expect(
          container.read(savedTransitControllerProvider).stopIds,
          equals([stop1, stop3, stop2]),
        );

        // Routes follow same order preservation
        await controller.saveRoute(route3);
        await controller.saveRoute(route1);
        await controller.saveRoute(route2);

        expect(
          container.read(savedTransitControllerProvider).routeIds,
          equals([route3, route1, route2]),
        );
      },
    );
  });

  group('SavedTransitController — Idempotent No-Ops', () {
    test('9. saveStop for an already-saved stop is a true no-op', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store: store);
      addTearDown(container.dispose);

      final controller = container.read(
        savedTransitControllerProvider.notifier,
      );
      await controller.saveStop(stop1);

      final stateBefore = container.read(savedTransitControllerProvider);
      await controller.saveStop(stop1);
      final stateAfter = container.read(savedTransitControllerProvider);

      expect(identical(stateBefore, stateAfter), isTrue);
    });

    test('10. unsaveStop for a missing stop is a true no-op', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store: store);
      addTearDown(container.dispose);

      final controller = container.read(
        savedTransitControllerProvider.notifier,
      );
      final stateBefore = container.read(savedTransitControllerProvider);
      await controller.unsaveStop(stop1);
      final stateAfter = container.read(savedTransitControllerProvider);

      expect(identical(stateBefore, stateAfter), isTrue);
    });

    test('11. saveRoute for an already-saved route is a true no-op', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store: store);
      addTearDown(container.dispose);

      final controller = container.read(
        savedTransitControllerProvider.notifier,
      );
      await controller.saveRoute(route1);

      final stateBefore = container.read(savedTransitControllerProvider);
      await controller.saveRoute(route1);
      final stateAfter = container.read(savedTransitControllerProvider);

      expect(identical(stateBefore, stateAfter), isTrue);
    });

    test('12. unsaveRoute for a missing route is a true no-op', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store: store);
      addTearDown(container.dispose);

      final controller = container.read(
        savedTransitControllerProvider.notifier,
      );
      final stateBefore = container.read(savedTransitControllerProvider);
      await controller.unsaveRoute(route1);
      final stateAfter = container.read(savedTransitControllerProvider);

      expect(identical(stateBefore, stateAfter), isTrue);
    });

    test('13. no-op mutations do not perform storage writes', () async {
      final spyStore = SpyKeyValueStore();
      final container = makeContainer(store: spyStore);
      addTearDown(container.dispose);

      final controller = container.read(
        savedTransitControllerProvider.notifier,
      );

      // Perform initial mutations
      await controller.saveStop(stop1);
      await controller.saveRoute(route1);
      expect(spyStore.writeCount, equals(2));

      // Idempotent operations must not perform any storage writes
      await controller.saveStop(stop1);
      expect(spyStore.writeCount, equals(2));

      await controller.unsaveStop(stop2); // missing stop
      expect(spyStore.writeCount, equals(2));

      await controller.saveRoute(route1);
      expect(spyStore.writeCount, equals(2));

      await controller.unsaveRoute(route2); // missing route
      expect(spyStore.writeCount, equals(2));
    });
  });

  group('SavedTransitController — StorageFailure Handling', () {
    test('14. StorageFailure during stop persistence retains optimistic state and propagates failure', () async {
      const expectedCause = 'Disk write failed';
      final failingStore = FailingWriteKeyValueStore(
        failureCause: expectedCause,
      );
      final container = makeContainer(store: failingStore);
      addTearDown(container.dispose);

      final controller = container.read(
        savedTransitControllerProvider.notifier,
      );

      // Optimistic state must be published, but StorageFailure rethrown to caller
      late StorageFailure caughtFailure;
      try {
        await controller.saveStop(stop1);
        fail('saveStop should have thrown StorageFailure');
      } on StorageFailure catch (f) {
        caughtFailure = f;
      }

      expect(caughtFailure.cause, equals(expectedCause));
      // Session state remains updated
      expect(
        container.read(savedTransitControllerProvider).containsStop(stop1),
        isTrue,
      );
      expect(
        container.read(savedTransitControllerProvider).stopIds,
        equals([stop1]),
      );

      // Now test unsaveStop failure on a seeded item
      final failingUnsaveStore = FailingWriteKeyValueStore(
        initial: {
          savedKey: jsonEncode({
            'version': 1,
            'stops': ['stop_1', 'stop_2'],
            'routes': [],
          }),
        },
      );
      final unsaveContainer = makeContainer(store: failingUnsaveStore);
      addTearDown(unsaveContainer.dispose);

      expect(
        () => unsaveContainer
            .read(savedTransitControllerProvider.notifier)
            .unsaveStop(stop1),
        throwsA(
          isA<StorageFailure>().having(
            (f) => f.cause,
            'cause',
            equals('Simulated write failure'),
          ),
        ),
      );

      // Optimistic state remains updated (stop1 removed)
      expect(
        unsaveContainer
            .read(savedTransitControllerProvider)
            .containsStop(stop1),
        isFalse,
      );
      expect(
        unsaveContainer.read(savedTransitControllerProvider).stopIds,
        equals([stop2]),
      );
    });

    test('15. StorageFailure during route persistence retains optimistic state and propagates failure', () async {
      const expectedCause = 'Route disk write failed';
      final failingStore = FailingWriteKeyValueStore(
        failureCause: expectedCause,
      );
      final container = makeContainer(store: failingStore);
      addTearDown(container.dispose);

      final controller = container.read(
        savedTransitControllerProvider.notifier,
      );

      late StorageFailure caughtFailure;
      try {
        await controller.saveRoute(route1);
        fail('saveRoute should have thrown StorageFailure');
      } on StorageFailure catch (f) {
        caughtFailure = f;
      }

      expect(caughtFailure.cause, equals(expectedCause));
      // Session state remains updated
      expect(
        container.read(savedTransitControllerProvider).containsRoute(route1),
        isTrue,
      );
      expect(
        container.read(savedTransitControllerProvider).routeIds,
        equals([route1]),
      );

      // Test unsaveRoute failure on seeded item
      final failingUnsaveStore = FailingWriteKeyValueStore(
        initial: {
          savedKey: jsonEncode({
            'version': 1,
            'stops': [],
            'routes': ['route_1', 'route_2'],
          }),
        },
      );
      final unsaveContainer = makeContainer(store: failingUnsaveStore);
      addTearDown(unsaveContainer.dispose);

      expect(
        () => unsaveContainer
            .read(savedTransitControllerProvider.notifier)
            .unsaveRoute(route1),
        throwsA(
          isA<StorageFailure>().having(
            (f) => f.cause,
            'cause',
            equals('Simulated write failure'),
          ),
        ),
      );

      // Optimistic state remains updated (route1 removed)
      expect(
        unsaveContainer
            .read(savedTransitControllerProvider)
            .containsRoute(route1),
        isFalse,
      );
      expect(
        unsaveContainer.read(savedTransitControllerProvider).routeIds,
        equals([route2]),
      );
    });
  });

  group('SavedTransitController — Roundtrip & Provider Isolation', () {
    test('16. successful persistence can be read back through the repository/store', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store: store);
      addTearDown(container.dispose);

      final controller = container.read(
        savedTransitControllerProvider.notifier,
      );
      await controller.saveStop(stop1);
      await controller.saveRoute(route1);
      await controller.saveStop(stop3);

      final repo = container.read(savedTransitRepositoryProvider);
      final fromRepo = repo.read();

      expect(fromRepo.stopIds, equals([stop1, stop3]));
      expect(fromRepo.routeIds, equals([route1]));
    });

    test(
      '17. provider/container isolation works correctly between tests',
      () async {
        final storeA = InMemoryKeyValueStore();
        final storeB = InMemoryKeyValueStore();

        final containerA = makeContainer(store: storeA);
        final containerB = makeContainer(store: storeB);
        addTearDown(containerA.dispose);
        addTearDown(containerB.dispose);

        await containerA
            .read(savedTransitControllerProvider.notifier)
            .saveStop(stop1);

        expect(
          containerA.read(savedTransitControllerProvider).stopIds,
          equals([stop1]),
        );
        expect(
          containerB.read(savedTransitControllerProvider).stopIds,
          isEmpty,
        );

        await containerB
            .read(savedTransitControllerProvider.notifier)
            .saveRoute(route2);

        expect(
          containerA.read(savedTransitControllerProvider).routeIds,
          isEmpty,
        );
        expect(
          containerB.read(savedTransitControllerProvider).routeIds,
          equals([route2]),
        );
      },
    );

    test(
      'DI: savedTransitRepositoryProvider constructs repository correctly',
      () {
        final store = InMemoryKeyValueStore();
        final container = makeContainer(store: store);
        addTearDown(container.dispose);

        final repo = container.read(savedTransitRepositoryProvider);
        expect(repo, isA<SavedTransitRepository>());
      },
    );
  });
}
