import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/logging/app_logger.dart';
import 'package:gramtransit_passenger/features/browse/application/browse_providers.dart';
import 'package:gramtransit_passenger/features/transit/data/bundled_timetable_repository.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/route_catalog.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/timetable_repository.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

class _FakeTimetableRepository implements TimetableRepository {
  _FakeTimetableRepository({this.timetable, this.error, this.completer});

  final Timetable? timetable;
  final Object? error;
  final Completer<Timetable>? completer;

  @override
  Future<Timetable> loadTimetable() async {
    if (completer != null) {
      return completer!.future;
    }
    if (error != null) {
      throw error!;
    }
    return timetable!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final stop1 = StopId('stop_1');
  final stop2 = StopId('stop_2');
  final stop3 = StopId('stop_3');
  final stop4 = StopId('stop_4');
  final stopUnused = StopId('stop_unused');

  final route1 = RouteId('route_1');
  final route2 = RouteId('route_2');
  final routeUnused = RouteId('route_unused');

  final canonicalStop1 = TransitStop(
    id: stop1,
    name: LocalizedText(english: 'Stop 1'),
  );
  final canonicalStop2 = TransitStop(
    id: stop2,
    name: LocalizedText(english: 'Stop 2'),
  );
  final canonicalStop3 = TransitStop(
    id: stop3,
    name: LocalizedText(english: 'Stop 3'),
  );
  final canonicalStop4 = TransitStop(
    id: stop4,
    name: LocalizedText(english: 'Stop 4'),
  );
  final canonicalStopUnused = TransitStop(
    id: stopUnused,
    name: LocalizedText(english: 'Unused Stop'),
  );

  final canonicalRoute1 = TransitRoute(
    id: route1,
    shortName: LocalizedText(english: '101'),
    longName: LocalizedText(english: 'Route One'),
  );
  final canonicalRoute2 = TransitRoute(
    id: route2,
    shortName: LocalizedText(english: '102'),
    longName: LocalizedText(english: 'Route Two'),
  );
  final canonicalRouteUnused = TransitRoute(
    id: routeUnused,
    shortName: LocalizedText(english: '999'),
    longName: LocalizedText(english: 'Unused Route'),
  );

  ScheduledTrip makeTrip({
    required String id,
    required RouteId routeId,
    required List<StopId> stops,
    ServiceTime? firstDeparture,
  }) {
    final startDep = firstDeparture ?? ServiceTime(hour: 8, minute: 0);
    final stopTimes = <StopTime>[];
    for (var i = 0; i < stops.length; i++) {
      final totalMinArr = startDep.hour * 60 + startDep.minute + i * 15;
      final totalMinDep = totalMinArr + 5;
      final arr = ServiceTime(
        hour: totalMinArr ~/ 60,
        minute: totalMinArr % 60,
      );
      final dep = ServiceTime(
        hour: totalMinDep ~/ 60,
        minute: totalMinDep % 60,
      );
      stopTimes.add(
        StopTime(stopId: stops[i], arrivalTime: arr, departureTime: dep),
      );
    }
    return ScheduledTrip(
      id: TripId(id),
      routeId: routeId,
      serviceDays: const ServiceDays(monday: true),
      stopTimes: stopTimes,
    );
  }

  // Trip 1 on route 1: stop 1 (origin) -> stop 2 (intermediate) -> stop 3 (terminal)
  final t1 = makeTrip(
    id: 't1',
    routeId: route1,
    stops: [stop1, stop2, stop3],
    firstDeparture: ServiceTime(hour: 8, minute: 0),
  );
  // Trip 2 on route 1: same stop sequence as t1, later time (for deduplication check)
  final t2 = makeTrip(
    id: 't2',
    routeId: route1,
    stops: [stop1, stop2, stop3],
    firstDeparture: ServiceTime(hour: 9, minute: 0),
  );
  // Trip 3 on route 2: stop 4 (origin) -> stop 2 (terminal)
  final t3 = makeTrip(
    id: 't3',
    routeId: route2,
    stops: [stop4, stop2],
    firstDeparture: ServiceTime(hour: 10, minute: 0),
  );

  final testTimetable = Timetable(
    info: TimetableInfo(datasetVersion: 'test-v1', isSampleData: true),
    stops: [
      canonicalStop1,
      canonicalStop2,
      canonicalStop3,
      canonicalStop4,
      canonicalStopUnused,
    ],
    routes: [canonicalRoute1, canonicalRoute2, canonicalRouteUnused],
    trips: [t1, t2, t3],
  );

  group('stopDetailsProvider', () {
    test('1. loading propagation', () {
      final completer = Completer<Timetable>();
      final fakeRepo = _FakeTimetableRepository(completer: completer);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final asyncVal = container.read(stopDetailsProvider(stop1));
      expect(asyncVal, isA<AsyncLoading<StopDetails?>>());
    });

    test('2. timetable error propagation', () async {
      final expectedError = DataFormatFailure(cause: 'Corrupt timetable');
      final fakeRepo = _FakeTimetableRepository(error: expectedError);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      try {
        await container.read(timetableProvider.future);
      } catch (_) {}

      final asyncVal = container.read(stopDetailsProvider(stop1));
      expect(asyncVal, isA<AsyncError<StopDetails?>>());
      expect(asyncVal.error, equals(expectedError));
    });

    test('3. known stop returns canonical TransitStop', () async {
      final fakeRepo = _FakeTimetableRepository(timetable: testTimetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final asyncVal = container.read(stopDetailsProvider(stop1));
      expect(asyncVal, isA<AsyncData<StopDetails?>>());
      final details = asyncVal.value!;
      expect(identical(details.stop, canonicalStop1), isTrue);
      expect(details.stop.id, equals(stop1));
      expect(details.stop.name.english, equals('Stop 1'));
    });

    test('4. routes match routesServingStop ordering', () async {
      // Create timetable with routes in order [canonicalRoute2, canonicalRoute1]
      final reorderedTimetable = Timetable(
        info: testTimetable.info,
        stops: testTimetable.stops,
        routes: [canonicalRoute2, canonicalRoute1, canonicalRouteUnused],
        trips: testTimetable.trips,
      );
      final fakeRepo = _FakeTimetableRepository(timetable: reorderedTimetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final expectedServing = routesServingStop(reorderedTimetable, stop2);
      expect(
        expectedServing.map((r) => r.id).toList(),
        equals([route2, route1]),
      );

      final details = container.read(stopDetailsProvider(stop2)).value!;
      expect(details.routes.length, equals(2));
      expect(details.routes[0].id, equals(route2));
      expect(details.routes[1].id, equals(route1));
      expect(
        details.routes.map((r) => r.id).toList(),
        equals(expectedServing.map((r) => r.id).toList()),
      );
    });

    test('5. intermediate/origin/terminal service is represented according to P3.1 projection', () async {
      final fakeRepo = _FakeTimetableRepository(timetable: testTimetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      // stop1 is origin for route1
      final detailsOrigin = container.read(stopDetailsProvider(stop1)).value!;
      expect(detailsOrigin.routes.map((r) => r.id).toList(), equals([route1]));

      // stop2 is intermediate for route1 and terminal for route2
      final detailsIntermediate = container
          .read(stopDetailsProvider(stop2))
          .value!;
      expect(
        detailsIntermediate.routes.map((r) => r.id).toList(),
        equals([route1, route2]),
      );

      // stop3 is terminal for route1
      final detailsTerminal = container.read(stopDetailsProvider(stop3)).value!;
      expect(
        detailsTerminal.routes.map((r) => r.id).toList(),
        equals([route1]),
      );
    });

    test(
      '6. route IDs are deduplicated through the canonical projection',
      () async {
        final fakeRepo = _FakeTimetableRepository(timetable: testTimetable);
        final container = ProviderContainer(
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        await container.read(timetableProvider.future);

        // Both t1 and t2 on route1 serve stop1
        final details = container.read(stopDetailsProvider(stop1)).value!;
        expect(details.routes.length, equals(1));
        expect(details.routes.first.id, equals(route1));
        expect(identical(details.routes.first, canonicalRoute1), isTrue);
      },
    );

    test(
      '7. known unused stop -> non-null StopDetails with empty routes',
      () async {
        final fakeRepo = _FakeTimetableRepository(timetable: testTimetable);
        final container = ProviderContainer(
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        await container.read(timetableProvider.future);

        final asyncVal = container.read(stopDetailsProvider(stopUnused));
        expect(asyncVal, isA<AsyncData<StopDetails?>>());
        final details = asyncVal.value;
        expect(details, isNotNull);
        expect(identical(details!.stop, canonicalStopUnused), isTrue);
        expect(details.routes, isEmpty);
      },
    );

    test('8. unknown stop -> AsyncData(null)', () async {
      final fakeRepo = _FakeTimetableRepository(timetable: testTimetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final asyncVal = container.read(
        stopDetailsProvider(StopId('unknown_stop_id')),
      );
      expect(asyncVal, isA<AsyncData<StopDetails?>>());
      expect(asyncVal.value, isNull);
    });

    test('9. routes list cannot be mutated', () async {
      final fakeRepo = _FakeTimetableRepository(timetable: testTimetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final details = container.read(stopDetailsProvider(stop1)).value!;
      expect(() => details.routes.add(canonicalRoute2), throwsUnsupportedError);
      expect(() => details.routes.clear(), throwsUnsupportedError);
    });
  });

  group('routeDetailsProvider', () {
    test('10. loading propagation', () {
      final completer = Completer<Timetable>();
      final fakeRepo = _FakeTimetableRepository(completer: completer);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final asyncVal = container.read(routeDetailsProvider(route1));
      expect(asyncVal, isA<AsyncLoading<RouteDetails?>>());
    });

    test('11. timetable error propagation', () async {
      final expectedError = DataFormatFailure(cause: 'Corrupt timetable');
      final fakeRepo = _FakeTimetableRepository(error: expectedError);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      try {
        await container.read(timetableProvider.future);
      } catch (_) {}

      final asyncVal = container.read(routeDetailsProvider(route1));
      expect(asyncVal, isA<AsyncError<RouteDetails?>>());
      expect(asyncVal.error, equals(expectedError));
    });

    test('12. known route returns canonical TransitRoute', () async {
      final fakeRepo = _FakeTimetableRepository(timetable: testTimetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final asyncVal = container.read(routeDetailsProvider(route1));
      expect(asyncVal, isA<AsyncData<RouteDetails?>>());
      final details = asyncVal.value!;
      expect(identical(details.route, canonicalRoute1), isTrue);
      expect(details.route.id, equals(route1));
      expect(details.route.shortName.english, equals('101'));
      expect(details.route.longName.english, equals('Route One'));
    });

    test('13. variants exactly reflect routeVariants output/order', () async {
      // Add a second variant to route1 (e.g. stop1 -> stop3)
      final tShort = makeTrip(
        id: 't_short',
        routeId: route1,
        stops: [stop1, stop3],
        firstDeparture: ServiceTime(hour: 12, minute: 0),
      );
      final multiVariantTimetable = Timetable(
        info: testTimetable.info,
        stops: testTimetable.stops,
        routes: testTimetable.routes,
        trips: [t1, t2, tShort, t3],
      );
      final fakeRepo = _FakeTimetableRepository(
        timetable: multiVariantTimetable,
      );
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final expectedVariants = routeVariants(multiVariantTimetable, route1);
      expect(expectedVariants.length, equals(2));

      final details = container.read(routeDetailsProvider(route1)).value!;
      expect(details.variants.length, equals(2));
      for (var i = 0; i < expectedVariants.length; i++) {
        expect(
          details.variants[i].stopIds,
          equals(expectedVariants[i].stopIds),
        );
        expect(
          details.variants[i].trips.map((t) => t.id).toList(),
          equals(expectedVariants[i].trips.map((t) => t.id).toList()),
        );
      }
    });

    test('14. trips/order inside variants remain the P3.1 result', () async {
      // Add trips out of chronological order
      final tripEarly = makeTrip(
        id: 't_early',
        routeId: route1,
        stops: [stop1, stop2, stop3],
        firstDeparture: ServiceTime(hour: 6, minute: 30),
      );
      final tripLate = makeTrip(
        id: 't_late',
        routeId: route1,
        stops: [stop1, stop2, stop3],
        firstDeparture: ServiceTime(hour: 22, minute: 0),
      );
      final tt = Timetable(
        info: testTimetable.info,
        stops: testTimetable.stops,
        routes: testTimetable.routes,
        trips: [tripLate, tripEarly, t1], // t1 is 08:00
      );
      final fakeRepo = _FakeTimetableRepository(timetable: tt);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final details = container.read(routeDetailsProvider(route1)).value!;
      expect(details.variants.length, equals(1));
      expect(
        details.variants.first.trips.map((t) => t.id.value).toList(),
        equals(['t_early', 't1', 't_late']),
      );
    });

    test(
      '15. known zero-trip route -> non-null RouteDetails with empty variants',
      () async {
        final fakeRepo = _FakeTimetableRepository(timetable: testTimetable);
        final container = ProviderContainer(
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        await container.read(timetableProvider.future);

        final asyncVal = container.read(routeDetailsProvider(routeUnused));
        expect(asyncVal, isA<AsyncData<RouteDetails?>>());
        final details = asyncVal.value;
        expect(details, isNotNull);
        expect(identical(details!.route, canonicalRouteUnused), isTrue);
        expect(details.variants, isEmpty);
      },
    );

    test('16. unknown route -> AsyncData(null)', () async {
      final fakeRepo = _FakeTimetableRepository(timetable: testTimetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final asyncVal = container.read(
        routeDetailsProvider(RouteId('unknown_route_id')),
      );
      expect(asyncVal, isA<AsyncData<RouteDetails?>>());
      expect(asyncVal.value, isNull);
    });

    test('17. variants list cannot be mutated', () async {
      final fakeRepo = _FakeTimetableRepository(timetable: testTimetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final details = container.read(routeDetailsProvider(route1)).value!;
      final dummyVariant = RouteVariant(
        routeId: route1,
        stopIds: [stop1, stop2],
        trips: [
          makeTrip(id: 'dummy', routeId: route1, stops: [stop1, stop2]),
        ],
      );

      expect(() => details.variants.add(dummyVariant), throwsUnsupportedError);
      expect(() => details.variants.clear(), throwsUnsupportedError);
    });
  });

  group('Bundled sample-v2 browse providers characterization', () {
    late Timetable sampleTimetable;

    setUpAll(() async {
      final repo = BundledTimetableRepository(
        bundle: rootBundle,
        logger: const AppLogger(),
        assetPath: 'assets/transit/timetable.json',
      );
      sampleTimetable = await repo.loadTimetable();
    });

    test(
      'sample-v2 stop_1 resolves with canonical stop and serving routes',
      () async {
        final fakeRepo = _FakeTimetableRepository(timetable: sampleTimetable);
        final container = ProviderContainer(
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        await container.read(timetableProvider.future);

        final asyncVal = container.read(stopDetailsProvider(StopId('stop_1')));
        expect(asyncVal, isA<AsyncData<StopDetails?>>());
        final details = asyncVal.value!;
        expect(details.stop.id, equals(StopId('stop_1')));
        expect(details.routes, isNotEmpty);
        expect(
          details.routes.map((r) => r.id.value).toList(),
          equals(
            routesServingStop(
              sampleTimetable,
              StopId('stop_1'),
            ).map((r) => r.id.value).toList(),
          ),
        );
      },
    );

    test(
      'sample-v2 route_1 resolves with canonical route and 3 variants',
      () async {
        final fakeRepo = _FakeTimetableRepository(timetable: sampleTimetable);
        final container = ProviderContainer(
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        await container.read(timetableProvider.future);

        final asyncVal = container.read(
          routeDetailsProvider(RouteId('route_1')),
        );
        expect(asyncVal, isA<AsyncData<RouteDetails?>>());
        final details = asyncVal.value!;
        expect(details.route.id, equals(RouteId('route_1')));
        expect(details.variants.length, equals(3));
        expect(
          details.variants[0].trips.map((t) => t.id.value).toList(),
          equals(['trip_1', 'trip_2']),
        );
      },
    );
  });
}
