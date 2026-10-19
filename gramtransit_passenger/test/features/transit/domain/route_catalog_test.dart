import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/core/logging/app_logger.dart';
import 'package:gramtransit_passenger/features/transit/data/bundled_timetable_repository.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/route_catalog.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final stop1 = StopId('stop_1');
  final stop2 = StopId('stop_2');
  final stop3 = StopId('stop_3');
  final stop4 = StopId('stop_4');

  final route1 = RouteId('route_1');
  final route2 = RouteId('route_2');

  ScheduledTrip makeTrip({
    required String id,
    required RouteId routeId,
    required List<StopId> stops,
    ServiceDays serviceDays = const ServiceDays(monday: true),
    ServiceTime? firstDeparture,
  }) {
    final startDep = firstDeparture ?? ServiceTime(hour: 8, minute: 0);
    final stopTimes = <StopTime>[];
    for (var i = 0; i < stops.length; i++) {
      final totalMinArr = startDep.hour * 60 + startDep.minute + i * 10;
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
      serviceDays: serviceDays,
      stopTimes: stopTimes,
    );
  }

  group('RouteVariant invariants', () {
    test('rejects stopIds with fewer than 2 stops', () {
      final trip = makeTrip(id: 't1', routeId: route1, stops: [stop1, stop2]);

      expect(
        () => RouteVariant(routeId: route1, stopIds: [], trips: [trip]),
        throwsArgumentError,
      );

      expect(
        () => RouteVariant(routeId: route1, stopIds: [stop1], trips: [trip]),
        throwsArgumentError,
      );
    });

    test('rejects empty trips', () {
      expect(
        () => RouteVariant(routeId: route1, stopIds: [stop1, stop2], trips: []),
        throwsArgumentError,
      );
    });

    test('rejects trip belonging to another route', () {
      final tripOfRoute2 = makeTrip(
        id: 't2',
        routeId: route2,
        stops: [stop1, stop2],
      );

      expect(
        () => RouteVariant(
          routeId: route1,
          stopIds: [stop1, stop2],
          trips: [tripOfRoute2],
        ),
        throwsArgumentError,
      );
    });

    test('rejects trip whose ordered stop sequence differs in length', () {
      final tripWith3Stops = makeTrip(
        id: 't3',
        routeId: route1,
        stops: [stop1, stop2, stop3],
      );

      expect(
        () => RouteVariant(
          routeId: route1,
          stopIds: [stop1, stop2],
          trips: [tripWith3Stops],
        ),
        throwsArgumentError,
      );
    });

    test('rejects trip whose ordered stop sequence differs in stops', () {
      final tripWithOtherStop = makeTrip(
        id: 't_diff',
        routeId: route1,
        stops: [stop1, stop3],
      );

      expect(
        () => RouteVariant(
          routeId: route1,
          stopIds: [stop1, stop2],
          trips: [tripWithOtherStop],
        ),
        throwsArgumentError,
      );
    });

    test('rejects trip whose ordered stop sequence is reversed', () {
      final reversedTrip = makeTrip(
        id: 't_rev',
        routeId: route1,
        stops: [stop2, stop1],
      );

      expect(
        () => RouteVariant(
          routeId: route1,
          stopIds: [stop1, stop2],
          trips: [reversedTrip],
        ),
        throwsArgumentError,
      );
    });

    test('exposes unmodifiable stopIds', () {
      final trip = makeTrip(id: 't1', routeId: route1, stops: [stop1, stop2]);
      final variant = RouteVariant(
        routeId: route1,
        stopIds: [stop1, stop2],
        trips: [trip],
      );

      expect(() => variant.stopIds.clear(), throwsUnsupportedError);
      expect(() => variant.stopIds.add(stop3), throwsUnsupportedError);
    });

    test('exposes unmodifiable trips', () {
      final trip = makeTrip(id: 't1', routeId: route1, stops: [stop1, stop2]);
      final variant = RouteVariant(
        routeId: route1,
        stopIds: [stop1, stop2],
        trips: [trip],
      );

      expect(() => variant.trips.clear(), throwsUnsupportedError);
      expect(() => variant.trips.add(trip), throwsUnsupportedError);
    });

    test('firstStopId, lastStopId, and stopCount are correct', () {
      final trip = makeTrip(
        id: 't1',
        routeId: route1,
        stops: [stop1, stop2, stop3],
      );
      final variant = RouteVariant(
        routeId: route1,
        stopIds: [stop1, stop2, stop3],
        trips: [trip],
      );

      expect(variant.firstStopId, stop1);
      expect(variant.lastStopId, stop3);
      expect(variant.stopCount, 3);
    });

    test('retains canonical ScheduledTrip object references', () {
      final canonicalTrip = makeTrip(
        id: 't_canon',
        routeId: route1,
        stops: [stop1, stop2],
      );
      final variant = RouteVariant(
        routeId: route1,
        stopIds: [stop1, stop2],
        trips: [canonicalTrip],
      );

      expect(identical(variant.trips.first, canonicalTrip), isTrue);
    });
  });

  group('routeVariants', () {
    late Timetable timetable;
    late ScheduledTrip t1;
    late ScheduledTrip t2;
    late ScheduledTrip t3;
    late ScheduledTrip t4;
    late ScheduledTrip t5;
    late ScheduledTrip tLateNight;

    setUp(() {
      // t1: route1, stop1 -> stop2, 08:00
      t1 = makeTrip(
        id: 'trip_1',
        routeId: route1,
        stops: [stop1, stop2],
        serviceDays: const ServiceDays(monday: true),
        firstDeparture: ServiceTime(hour: 8, minute: 5),
      );
      // t2: route1, stop1 -> stop2, 09:00, sunday
      t2 = makeTrip(
        id: 'trip_2',
        routeId: route1,
        stops: [stop1, stop2],
        serviceDays: const ServiceDays(sunday: true),
        firstDeparture: ServiceTime(hour: 9, minute: 5),
      );
      // t3: route1, stop1 -> stop3 -> stop2, 12:00
      t3 = makeTrip(
        id: 'trip_3',
        routeId: route1,
        stops: [stop1, stop3, stop2],
        firstDeparture: ServiceTime(hour: 12, minute: 0),
      );
      // t4: route1, stop2 -> stop3 -> stop1 (reverse), 17:00
      t4 = makeTrip(
        id: 'trip_4',
        routeId: route1,
        stops: [stop2, stop3, stop1],
        firstDeparture: ServiceTime(hour: 17, minute: 0),
      );
      // t5: route2, stop4 -> stop1, 09:00
      t5 = makeTrip(
        id: 'trip_5',
        routeId: route2,
        stops: [stop4, stop1],
        firstDeparture: ServiceTime(hour: 9, minute: 0),
      );
      // tLateNight: route1, stop1 -> stop2, 24:15
      tLateNight = makeTrip(
        id: 'trip_late',
        routeId: route1,
        stops: [stop1, stop2],
        firstDeparture: ServiceTime(hour: 24, minute: 15),
      );

      timetable = Timetable(
        info: TimetableInfo(datasetVersion: 'test', isSampleData: true),
        stops: [
          TransitStop(
            id: stop1,
            name: LocalizedText(english: 'Stop 1'),
          ),
          TransitStop(
            id: stop2,
            name: LocalizedText(english: 'Stop 2'),
          ),
          TransitStop(
            id: stop3,
            name: LocalizedText(english: 'Stop 3'),
          ),
          TransitStop(
            id: stop4,
            name: LocalizedText(english: 'Stop 4'),
          ),
        ],
        routes: [
          TransitRoute(
            id: route1,
            shortName: LocalizedText(english: '1A'),
            longName: LocalizedText(english: 'Route 1'),
          ),
          TransitRoute(
            id: route2,
            shortName: LocalizedText(english: '2B'),
            longName: LocalizedText(english: 'Route 2'),
          ),
          TransitRoute(
            id: RouteId('route_empty'),
            shortName: LocalizedText(english: '3C'),
            longName: LocalizedText(english: 'Route Empty'),
          ),
        ],
        trips: [t1, t2, t3, t4, t5, tLateNight],
      );
    });

    test('unknown route => ArgumentError', () {
      expect(
        () => routeVariants(timetable, RouteId('unknown_route')),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Route not found in timetable',
          ),
        ),
      );
    });

    test('known route with zero trips => empty list', () {
      final variants = routeVariants(timetable, RouteId('route_empty'));
      expect(variants, isEmpty);
      final dummyVariant = RouteVariant(
        routeId: route1,
        stopIds: [stop1, stop2],
        trips: [t1],
      );
      expect(() => variants.add(dummyVariant), throwsUnsupportedError);
    });

    test('identical stop sequence groups together despite different service days and times', () {
      final variants = routeVariants(timetable, route1);
      final variant1 = variants.firstWhere(
        (v) => v.stopIds.length == 2 && v.stopIds.first == stop1,
      );
      expect(variant1.stopIds, [stop1, stop2]);
      expect(variant1.trips.length, 3); // t1, t2, tLateNight
    });

    test('reverse sequence forms a separate variant', () {
      final variants = routeVariants(timetable, route1);
      final forward = variants.where(
        (v) => v.stopIds.first == stop1 && v.stopIds.last == stop2,
      );
      final reverse = variants.where(
        (v) => v.stopIds.first == stop2 && v.stopIds.last == stop1,
      );
      expect(forward, isNotEmpty);
      expect(reverse, isNotEmpty);
      expect(identical(forward.first, reverse.first), isFalse);
    });

    test('short-turn forms a separate variant', () {
      final shortTrip = makeTrip(
        id: 't_short',
        routeId: route1,
        stops: [stop1, stop3], // short-turn before stop2
        firstDeparture: ServiceTime(hour: 14, minute: 0),
      );
      final tt = Timetable(
        info: timetable.info,
        stops: timetable.stops,
        routes: timetable.routes,
        trips: [t3, shortTrip],
      );

      final variants = routeVariants(tt, route1);
      expect(variants.length, 2);
      expect(variants[0].stopIds, [stop1, stop3, stop2]);
      expect(variants[1].stopIds, [stop1, stop3]);
    });

    test(
      'different intermediate/skip-stop pattern forms a separate variant',
      () {
        final variants = routeVariants(timetable, route1);
        // t1 is stop1 -> stop2 (skips stop3)
        // t3 is stop1 -> stop3 -> stop2
        final directVariant = variants.firstWhere((v) => v.stopIds.length == 2);
        final viaStop3Variant = variants.firstWhere(
          (v) => v.stopIds.length == 3,
        );

        expect(directVariant.stopIds, [stop1, stop2]);
        expect(viaStop3Variant.stopIds, [stop1, stop3, stop2]);
      },
    );

    test('variant order follows first appearance in timetable.trips', () {
      // In timetable.trips:
      // t1: stop1 -> stop2 (first appearance of variant A)
      // t3: stop1 -> stop3 -> stop2 (first appearance of variant B)
      // t4: stop2 -> stop3 -> stop1 (first appearance of variant C)
      final variants = routeVariants(timetable, route1);
      expect(variants.length, 3);
      expect(variants[0].stopIds, [stop1, stop2]);
      expect(variants[1].stopIds, [stop1, stop3, stop2]);
      expect(variants[2].stopIds, [stop2, stop3, stop1]);
    });

    test(
      'variant order changes if trip sequence order changes in timetable.trips',
      () {
        final ttReordered = Timetable(
          info: timetable.info,
          stops: timetable.stops,
          routes: timetable.routes,
          trips: [t4, t3, t1], // t4 first, then t3, then t1
        );
        final variants = routeVariants(ttReordered, route1);
        expect(variants.length, 3);
        expect(variants[0].stopIds, [stop2, stop3, stop1]);
        expect(variants[1].stopIds, [stop1, stop3, stop2]);
        expect(variants[2].stopIds, [stop1, stop2]);
      },
    );

    test('trips inside variant sorted by first-stop departure ServiceTime', () {
      final tripEarly = makeTrip(
        id: 't_early',
        routeId: route1,
        stops: [stop1, stop2],
        firstDeparture: ServiceTime(hour: 6, minute: 30),
      );
      final tripMid = makeTrip(
        id: 't_mid',
        routeId: route1,
        stops: [stop1, stop2],
        firstDeparture: ServiceTime(hour: 10, minute: 0),
      );
      final tripEvening = makeTrip(
        id: 't_eve',
        routeId: route1,
        stops: [stop1, stop2],
        firstDeparture: ServiceTime(hour: 20, minute: 15),
      );

      // Add them out of order in timetable
      final tt = Timetable(
        info: timetable.info,
        stops: timetable.stops,
        routes: timetable.routes,
        trips: [tripEvening, tripEarly, tripMid],
      );

      final variants = routeVariants(tt, route1);
      expect(variants.first.trips.map((t) => t.id.value).toList(), [
        't_early',
        't_mid',
        't_eve',
      ]);
    });

    test(
      '24:xx departure sorts after 23:xx without modulo 24 normalization',
      () {
        final trip23 = makeTrip(
          id: 't_23',
          routeId: route1,
          stops: [stop1, stop2],
          firstDeparture: ServiceTime(hour: 23, minute: 50),
        );
        final trip24 = makeTrip(
          id: 't_24',
          routeId: route1,
          stops: [stop1, stop2],
          firstDeparture: ServiceTime(hour: 24, minute: 10),
        );

        // Put 24:10 before 23:50 in timetable
        final tt = Timetable(
          info: timetable.info,
          stops: timetable.stops,
          routes: timetable.routes,
          trips: [trip24, trip23],
        );

        final variants = routeVariants(tt, route1);
        final sortedIds = variants.first.trips.map((t) => t.id.value).toList();
        expect(sortedIds, ['t_23', 't_24']);
      },
    );

    test('equal departure time uses TripId.value lexicographic tie-break', () {
      final tripZ = makeTrip(
        id: 'trip_Z',
        routeId: route1,
        stops: [stop1, stop2],
        firstDeparture: ServiceTime(hour: 10, minute: 0),
      );
      final tripA = makeTrip(
        id: 'trip_A',
        routeId: route1,
        stops: [stop1, stop2],
        firstDeparture: ServiceTime(hour: 10, minute: 0),
      );
      final tripM = makeTrip(
        id: 'trip_M',
        routeId: route1,
        stops: [stop1, stop2],
        firstDeparture: ServiceTime(hour: 10, minute: 0),
      );

      final tt = Timetable(
        info: timetable.info,
        stops: timetable.stops,
        routes: timetable.routes,
        trips: [tripZ, tripA, tripM],
      );

      final variants = routeVariants(tt, route1);
      final sortedIds = variants.first.trips.map((t) => t.id.value).toList();
      expect(sortedIds, ['trip_A', 'trip_M', 'trip_Z']);
    });

    test('source timetable trip order is not mutated and canonical references are retained', () {
      final originalTripOrder = List<ScheduledTrip>.from(timetable.trips);
      final variants = routeVariants(timetable, route1);

      expect(timetable.trips, equals(originalTripOrder));
      expect(identical(variants.first.trips.first, t1), isTrue);
    });
  });

  group('routesServingStop', () {
    late Timetable timetable;
    final r1 = TransitRoute(
      id: route1,
      shortName: LocalizedText(english: '1A'),
      longName: LocalizedText(english: 'Route 1'),
    );
    final r2 = TransitRoute(
      id: route2,
      shortName: LocalizedText(english: '2B'),
      longName: LocalizedText(english: 'Route 2'),
    );
    final rUnused = TransitRoute(
      id: RouteId('route_unused'),
      shortName: LocalizedText(english: '3C'),
      longName: LocalizedText(english: 'Route Unused'),
    );

    setUp(() {
      final t1 = makeTrip(
        id: 't1',
        routeId: route1,
        stops: [
          stop1,
          stop2,
          stop3,
        ], // stop1 origin, stop2 intermediate, stop3 terminal
      );
      final t2 = makeTrip(
        id: 't2',
        routeId: route1,
        stops: [stop1, stop2], // second trip on route1
      );
      final t3 = makeTrip(
        id: 't3',
        routeId: route2,
        stops: [stop4, stop2], // stop4 origin, stop2 terminal
      );

      timetable = Timetable(
        info: TimetableInfo(datasetVersion: 'test', isSampleData: true),
        stops: [
          TransitStop(
            id: stop1,
            name: LocalizedText(english: 'Stop 1'),
          ),
          TransitStop(
            id: stop2,
            name: LocalizedText(english: 'Stop 2'),
          ),
          TransitStop(
            id: stop3,
            name: LocalizedText(english: 'Stop 3'),
          ),
          TransitStop(
            id: stop4,
            name: LocalizedText(english: 'Stop 4'),
          ),
          TransitStop(
            id: StopId('stop_unused'),
            name: LocalizedText(english: 'Unused Stop'),
          ),
        ],
        routes: [r1, r2, rUnused],
        trips: [t1, t2, t3],
      );
    });

    test('unknown stop => ArgumentError', () {
      expect(
        () => routesServingStop(timetable, StopId('unknown_stop')),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Stop not found in timetable',
          ),
        ),
      );
    });

    test('known unused stop => empty list', () {
      final routes = routesServingStop(timetable, StopId('stop_unused'));
      expect(routes, isEmpty);
      expect(() => routes.add(r1), throwsUnsupportedError);
    });

    test('origin stop counts', () {
      // stop1 is origin for route1
      final routes = routesServingStop(timetable, stop1);
      expect(routes, [r1]);
    });

    test('intermediate stop counts', () {
      // stop2 is intermediate for t1 (route1) and terminal for t3 (route2)
      final routes = routesServingStop(timetable, stop2);
      expect(routes, [r1, r2]);
    });

    test('terminal stop counts', () {
      // stop3 is terminal for route1
      final routes = routesServingStop(timetable, stop3);
      expect(routes, [r1]);
    });

    test('route is deduplicated when multiple trips visit stop', () {
      // Both t1 and t2 on route1 visit stop1
      final routes = routesServingStop(timetable, stop1);
      expect(routes.length, 1);
      expect(routes.first.id, route1);
    });

    test('output follows canonical timetable.routes order', () {
      // Re-order timetable.routes so r2 comes before r1
      final ttReordered = Timetable(
        info: timetable.info,
        stops: timetable.stops,
        routes: [r2, r1, rUnused],
        trips: timetable.trips,
      );

      final routes = routesServingStop(ttReordered, stop2);
      expect(routes.map((r) => r.id).toList(), [route2, route1]);
    });

    test('routes with no serving trips are excluded', () {
      final routesForStop1 = routesServingStop(timetable, stop1);
      expect(
        routesForStop1.any((r) => r.id == RouteId('route_unused')),
        isFalse,
      );
    });
  });

  group('Bundled sample-v2 catalog characterization', () {
    late Timetable sampleTimetable;

    setUpAll(() async {
      final repo = BundledTimetableRepository(
        bundle: rootBundle,
        logger: const AppLogger(),
        assetPath: 'assets/transit/timetable.json',
      );
      sampleTimetable = await repo.loadTimetable();
    });

    test('route_1 projections match frozen sample-v2 specifications', () {
      final variants = routeVariants(sampleTimetable, RouteId('route_1'));
      expect(variants.length, 3);

      // Variant 1: stop_1 -> stop_2, contains trip_1 and trip_2 chronologically ordered
      final v1 = variants[0];
      expect(v1.stopIds, [StopId('stop_1'), StopId('stop_2')]);
      expect(v1.trips.map((t) => t.id.value).toList(), ['trip_1', 'trip_2']);
      expect(v1.firstStopId, StopId('stop_1'));
      expect(v1.lastStopId, StopId('stop_2'));
      expect(v1.stopCount, 2);

      // Variant 2: stop_1 -> stop_3 -> stop_2, contains trip_3
      final v2 = variants[1];
      expect(v2.stopIds, [
        StopId('stop_1'),
        StopId('stop_3'),
        StopId('stop_2'),
      ]);
      expect(v2.trips.map((t) => t.id.value).toList(), ['trip_3']);
      expect(v2.firstStopId, StopId('stop_1'));
      expect(v2.lastStopId, StopId('stop_2'));
      expect(v2.stopCount, 3);

      // Variant 3: stop_2 -> stop_3 -> stop_1, contains trip_4
      final v3 = variants[2];
      expect(v3.stopIds, [
        StopId('stop_2'),
        StopId('stop_3'),
        StopId('stop_1'),
      ]);
      expect(v3.trips.map((t) => t.id.value).toList(), ['trip_4']);
      expect(v3.firstStopId, StopId('stop_2'));
      expect(v3.lastStopId, StopId('stop_1'));
      expect(v3.stopCount, 3);
    });

    test('route_2 projections match frozen sample-v2 specifications', () {
      final variants = routeVariants(sampleTimetable, RouteId('route_2'));
      expect(variants.length, 1);

      // Variant 1: stop_4 -> stop_1, contains trip_5
      final v1 = variants[0];
      expect(v1.stopIds, [StopId('stop_4'), StopId('stop_1')]);
      expect(v1.trips.map((t) => t.id.value).toList(), ['trip_5']);
      expect(v1.firstStopId, StopId('stop_4'));
      expect(v1.lastStopId, StopId('stop_1'));
      expect(v1.stopCount, 2);
    });

    test(
      'stop_1 is served by route_1 and route_2 in canonical route order',
      () {
        final routes = routesServingStop(sampleTimetable, StopId('stop_1'));
        expect(routes.map((r) => r.id.value).toList(), ['route_1', 'route_2']);
      },
    );

    test('other sample-v2 stops are correctly served', () {
      final routes2 = routesServingStop(sampleTimetable, StopId('stop_2'));
      expect(routes2.map((r) => r.id.value).toList(), ['route_1']);

      final routes3 = routesServingStop(sampleTimetable, StopId('stop_3'));
      expect(routes3.map((r) => r.id.value).toList(), ['route_1']);

      final routes4 = routesServingStop(sampleTimetable, StopId('stop_4'));
      expect(routes4.map((r) => r.id.value).toList(), ['route_2']);
    });

    test('every canonical route in sample-v2 projects without failure', () {
      for (final route in sampleTimetable.routes) {
        final variants = routeVariants(sampleTimetable, route.id);
        expect(variants, isNotNull);
        for (final v in variants) {
          expect(v.routeId, route.id);
          expect(v.stopCount, greaterThanOrEqualTo(2));
          expect(v.trips, isNotEmpty);
        }
      }
    });

    test('every canonical stop in sample-v2 projects without failure', () {
      for (final stop in sampleTimetable.stops) {
        final routes = routesServingStop(sampleTimetable, stop.id);
        expect(routes, isNotNull);
        for (final r in routes) {
          expect(sampleTimetable.routes.contains(r), isTrue);
        }
      }
    });
  });
}
