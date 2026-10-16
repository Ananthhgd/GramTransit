import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/time/time_providers.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/timetable_repository.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/domain/scheduled_journey.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

class _FakeTimetableRepository implements TimetableRepository {
  final Timetable? result;
  final Object? error;
  int callCount = 0;

  _FakeTimetableRepository({this.result, this.error});

  @override
  Future<Timetable> loadTimetable() async {
    callCount++;
    if (error != null) {
      throw error!;
    }
    return result!;
  }
}

final class _DisposeObserver extends ProviderObserver {
  final Set<String> disposedProviders = {};

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    if (context.provider.name != null) {
      disposedProviders.add(context.provider.name!);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Timetable testTimetable;
  late StopId stopAlphaCentral;
  late StopId stopAlphaBeta;
  late StopId stopCentralStation;
  late StopId stopDeltaPort;

  setUp(() {
    stopAlphaCentral = StopId('stop_alpha_central');
    stopAlphaBeta = StopId('stop_alpha_beta');
    stopCentralStation = StopId('stop_central_station');
    stopDeltaPort = StopId('stop_delta_port');
    final route1 = RouteId('route_1');
    final route2 = RouteId('route_2');

    testTimetable = Timetable(
      info: TimetableInfo(datasetVersion: 'P2.3', isSampleData: true),
      stops: [
        TransitStop(
          id: stopAlphaCentral,
          name: LocalizedText(english: 'Alpha Central'),
        ),
        TransitStop(
          id: stopAlphaBeta,
          name: LocalizedText(english: 'Alpha Beta'),
        ),
        TransitStop(
          id: stopCentralStation,
          name: LocalizedText(english: 'Central Station'),
        ),
        TransitStop(
          id: stopDeltaPort,
          name: LocalizedText(english: 'Delta Port'),
        ),
      ],
      routes: [
        TransitRoute(
          id: route1,
          shortName: LocalizedText(english: '101'),
          longName: LocalizedText(english: 'Alpha to Central'),
        ),
        TransitRoute(
          id: route2,
          shortName: LocalizedText(english: '202'),
          longName: LocalizedText(english: 'Weekend Express'),
        ),
      ],
      trips: [
        // Daily morning trip
        ScheduledTrip(
          id: TripId('trip_morning'),
          routeId: route1,
          serviceDays: const ServiceDays(
            monday: true,
            tuesday: true,
            wednesday: true,
            thursday: true,
            friday: true,
            saturday: true,
            sunday: true,
          ),
          stopTimes: [
            StopTime(
              stopId: stopAlphaCentral,
              arrivalTime: ServiceTime(hour: 8, minute: 0),
              departureTime: ServiceTime(hour: 8, minute: 0),
            ),
            StopTime(
              stopId: stopAlphaBeta,
              arrivalTime: ServiceTime(hour: 8, minute: 15),
              departureTime: ServiceTime(hour: 8, minute: 15),
            ),
            StopTime(
              stopId: stopCentralStation,
              arrivalTime: ServiceTime(hour: 8, minute: 30),
              departureTime: ServiceTime(hour: 8, minute: 30),
            ),
          ],
        ),
        // Daily noon trip
        ScheduledTrip(
          id: TripId('trip_noon'),
          routeId: route1,
          serviceDays: const ServiceDays(
            monday: true,
            tuesday: true,
            wednesday: true,
            thursday: true,
            friday: true,
            saturday: true,
            sunday: true,
          ),
          stopTimes: [
            StopTime(
              stopId: stopAlphaCentral,
              arrivalTime: ServiceTime(hour: 12, minute: 0),
              departureTime: ServiceTime(hour: 12, minute: 0),
            ),
            StopTime(
              stopId: stopAlphaBeta,
              arrivalTime: ServiceTime(hour: 12, minute: 15),
              departureTime: ServiceTime(hour: 12, minute: 15),
            ),
            StopTime(
              stopId: stopCentralStation,
              arrivalTime: ServiceTime(hour: 12, minute: 30),
              departureTime: ServiceTime(hour: 12, minute: 30),
            ),
          ],
        ),
        // Tuesday-only trip (for nextLater verification when queried on Monday afternoon)
        ScheduledTrip(
          id: TripId('trip_tuesday_only'),
          routeId: route2,
          serviceDays: const ServiceDays(
            monday: false,
            tuesday: true,
            wednesday: false,
            thursday: false,
            friday: false,
            saturday: false,
            sunday: false,
          ),
          stopTimes: [
            StopTime(
              stopId: stopAlphaCentral,
              arrivalTime: ServiceTime(hour: 9, minute: 0),
              departureTime: ServiceTime(hour: 9, minute: 0),
            ),
            StopTime(
              stopId: stopCentralStation,
              arrivalTime: ServiceTime(hour: 9, minute: 45),
              departureTime: ServiceTime(hour: 9, minute: 45),
            ),
          ],
        ),
      ],
    );
  });

  group('StopSearchQuery & JourneyQuery parameter value types', () {
    test('StopSearchQuery supports value equality and hashCode', () {
      final q1 = StopSearchQuery(
        query: 'alpha',
        excludedStopId: StopId('stop_1'),
      );
      final q2 = StopSearchQuery(
        query: 'alpha',
        excludedStopId: StopId('stop_1'),
      );
      final q3 = StopSearchQuery(
        query: 'alpha',
        excludedStopId: StopId('stop_2'),
      );
      final q4 = StopSearchQuery(query: 'beta', excludedStopId: null);

      expect(q1, equals(q2));
      expect(q1.hashCode, equals(q2.hashCode));
      expect(q1, isNot(equals(q3)));
      expect(q1, isNot(equals(q4)));
      expect(q1.toString(), contains('StopSearchQuery'));
    });

    test('JourneyQuery supports value equality and hashCode', () {
      final j1 = JourneyQuery(
        boardingStopId: StopId('stop_A'),
        alightingStopId: StopId('stop_B'),
      );
      final j2 = JourneyQuery(
        boardingStopId: StopId('stop_A'),
        alightingStopId: StopId('stop_B'),
      );
      final j3 = JourneyQuery(
        boardingStopId: StopId('stop_B'),
        alightingStopId: StopId('stop_A'),
      );

      expect(j1, equals(j2));
      expect(j1.hashCode, equals(j2.hashCode));
      expect(j1, isNot(equals(j3)));
      expect(j1.toString(), contains('JourneyQuery'));
    });
  });

  group('stopSearchProvider', () {
    test('1. loaded timetable produces expected search results', () async {
      final fakeRepo = _FakeTimetableRepository(result: testTimetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final query = const StopSearchQuery(query: 'central');
      final asyncValue = container.read(stopSearchProvider(query));

      expect(asyncValue, isA<AsyncData<List<TransitStop>>>());
      final stops = asyncValue.requireValue;
      // 'Alpha Central' and 'Central Station' match 'central'
      expect(stops.length, equals(2));
      final names = stops.map((s) => s.name.english).toList();
      expect(names, containsAll(['Alpha Central', 'Central Station']));
    });

    test('2. excludedStopId is respected', () async {
      final fakeRepo = _FakeTimetableRepository(result: testTimetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final query = StopSearchQuery(
        query: 'central',
        excludedStopId: stopAlphaCentral,
      );
      final asyncValue = container.read(stopSearchProvider(query));

      expect(asyncValue, isA<AsyncData<List<TransitStop>>>());
      final stops = asyncValue.requireValue;
      expect(stops.length, equals(1));
      expect(stops.single.id, equals(stopCentralStation));
    });

    test('3. domain ranking/order is preserved', () async {
      final fakeRepo = _FakeTimetableRepository(result: testTimetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      // 'alpha beta' exact match bucket 1; 'alpha central' starts with 'alpha' bucket 2
      final query = const StopSearchQuery(query: 'alpha beta');
      final asyncValue = container.read(stopSearchProvider(query));

      expect(asyncValue, isA<AsyncData<List<TransitStop>>>());
      final stops = asyncValue.requireValue;
      expect(stops.first.name.english, equals('Alpha Beta'));
    });

    test(
      '4. empty query returns all eligible stops in timetable order',
      () async {
        final fakeRepo = _FakeTimetableRepository(result: testTimetable);
        final container = ProviderContainer(
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        await container.read(timetableProvider.future);

        final query = const StopSearchQuery(query: '');
        final asyncValue = container.read(stopSearchProvider(query));

        expect(asyncValue, isA<AsyncData<List<TransitStop>>>());
        final stops = asyncValue.requireValue;
        expect(stops.length, equals(testTimetable.stops.length));
        expect(
          stops.map((s) => s.id),
          equals(testTimetable.stops.map((s) => s.id)),
        );
      },
    );

    test('5. timetable loading/error behavior propagates according to existing provider semantics', () async {
      // 5a. Loading state
      final completer = Completer<Timetable>();
      final pendingRepo = _FakeTimetableRepository();
      final containerLoading = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(pendingRepo),
          timetableProvider.overrideWith((ref) => completer.future),
        ],
      );
      addTearDown(containerLoading.dispose);

      final loadingValue = containerLoading.read(
        stopSearchProvider(const StopSearchQuery(query: 'alpha')),
      );
      expect(loadingValue, isA<AsyncLoading<List<TransitStop>>>());

      // 5b. Error state
      final failure = DataFormatFailure(cause: 'Corrupt timetable');
      final failingRepo = _FakeTimetableRepository(error: failure);
      final containerError = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(failingRepo)],
      );
      addTearDown(containerError.dispose);

      try {
        await containerError.read(timetableProvider.future);
      } catch (_) {}

      final errorValue = containerError.read(
        stopSearchProvider(const StopSearchQuery(query: 'alpha')),
      );
      expect(errorValue, isA<AsyncError<List<TransitStop>>>());
      expect(errorValue.error, equals(failure));
    });

    test(
      '6. logically equal provider arguments behave correctly as value keys',
      () async {
        final fakeRepo = _FakeTimetableRepository(result: testTimetable);
        final container = ProviderContainer(
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        await container.read(timetableProvider.future);

        final q1 = StopSearchQuery(
          query: 'alpha',
          excludedStopId: stopAlphaCentral,
        );
        final q2 = StopSearchQuery(
          query: 'alpha',
          excludedStopId: StopId('stop_alpha_central'),
        );

        final sub1 = container.listen(stopSearchProvider(q1), (_, _) {});
        final sub2 = container.listen(stopSearchProvider(q2), (_, _) {});
        addTearDown(sub1.close);
        addTearDown(sub2.close);

        final val1 = container.read(stopSearchProvider(q1));
        final val2 = container.read(stopSearchProvider(q2));

        expect(val1, equals(val2));
      },
    );

    test(
      'stopSearchProvider autoDispose cleans up when subscription ends',
      () async {
        final fakeRepo = _FakeTimetableRepository(result: testTimetable);
        final observer = _DisposeObserver();
        final container = ProviderContainer(
          observers: [observer],
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        await container.read(timetableProvider.future);

        final q = const StopSearchQuery(query: 'alpha');
        final sub = container.listen(stopSearchProvider(q), (_, _) {});

        expect(
          observer.disposedProviders.contains('stopSearchProvider'),
          isFalse,
        );

        sub.close();
        await Future.delayed(Duration.zero);

        expect(
          observer.disposedProviders.contains('stopSearchProvider'),
          isTrue,
        );
      },
    );
  });

  group('upcomingJourneysProvider', () {
    test('7. provider returns expected direct journey for valid boarding/alighting pair', () async {
      final fakeRepo = _FakeTimetableRepository(result: testTimetable);
      final tickerController = StreamController<DateTime>.broadcast();
      final queryTime = DateTime(
        2026,
        1,
        5,
        7,
        30,
      ); // Monday morning before 8:00

      final container = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepo),
          minuteTickerProvider.overrideWith((ref) => tickerController.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(tickerController.close);

      await container.read(timetableProvider.future);

      final query = JourneyQuery(
        boardingStopId: stopAlphaCentral,
        alightingStopId: stopCentralStation,
      );

      final sub = container.listen(upcomingJourneysProvider(query), (_, _) {});
      addTearDown(sub.close);

      tickerController.add(queryTime);
      await Future.delayed(const Duration(milliseconds: 10));

      final asyncValue = container.read(upcomingJourneysProvider(query));
      expect(asyncValue, isA<AsyncData<UpcomingJourneys>>());

      final journeys = asyncValue.requireValue;
      expect(journeys.boardingStopId, equals(stopAlphaCentral));
      expect(journeys.alightingStopId, equals(stopCentralStation));
      expect(journeys.queryTime, equals(queryTime));
      expect(journeys.current.length, equals(2));
      expect(journeys.current[0].tripId, equals(TripId('trip_morning')));
      expect(journeys.current[1].tripId, equals(TripId('trip_noon')));
    });

    test('8. boarding/alighting IDs are passed correctly', () async {
      final fakeRepo = _FakeTimetableRepository(result: testTimetable);
      final tickerController = StreamController<DateTime>.broadcast();
      final queryTime = DateTime(2026, 1, 5, 7, 30);

      final container = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepo),
          minuteTickerProvider.overrideWith((ref) => tickerController.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(tickerController.close);

      await container.read(timetableProvider.future);

      // Intermediate boarding: Alpha Beta -> Central Station
      final query = JourneyQuery(
        boardingStopId: stopAlphaBeta,
        alightingStopId: stopCentralStation,
      );

      final sub = container.listen(upcomingJourneysProvider(query), (_, _) {});
      addTearDown(sub.close);

      tickerController.add(queryTime);
      await Future.delayed(const Duration(milliseconds: 10));

      final asyncValue = container.read(upcomingJourneysProvider(query));
      expect(asyncValue, isA<AsyncData<UpcomingJourneys>>());

      final journeys = asyncValue.requireValue;
      expect(journeys.boardingStopId, equals(stopAlphaBeta));
      expect(journeys.alightingStopId, equals(stopCentralStation));
      expect(journeys.current.first.boardingStopId, equals(stopAlphaBeta));
      expect(
        journeys.current.first.alightingStopId,
        equals(stopCentralStation),
      );
      expect(
        journeys.current.first.scheduledDeparture,
        equals(DateTime(2026, 1, 5, 8, 15)),
      );
    });

    test('9. current query time comes from injected/frozen Clock mechanism, not wall clock', () async {
      final fakeRepo = _FakeTimetableRepository(result: testTimetable);
      final tickerController = StreamController<DateTime>.broadcast();
      final frozenTime = DateTime(2026, 6, 15, 11, 45); // Monday June 15

      final container = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepo),
          minuteTickerProvider.overrideWith((ref) => tickerController.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(tickerController.close);

      await container.read(timetableProvider.future);

      final query = JourneyQuery(
        boardingStopId: stopAlphaCentral,
        alightingStopId: stopCentralStation,
      );

      final sub = container.listen(upcomingJourneysProvider(query), (_, _) {});
      addTearDown(sub.close);

      tickerController.add(frozenTime);
      await Future.delayed(const Duration(milliseconds: 10));

      final asyncValue = container.read(upcomingJourneysProvider(query));
      expect(asyncValue, isA<AsyncData<UpcomingJourneys>>());
      final result = asyncValue.requireValue;
      expect(result.queryTime, equals(frozenTime));
      // At 11:45, trip_morning (08:00) has already departed. Only trip_noon (12:00) is current.
      expect(result.current.length, equals(1));
      expect(result.current.single.tripId, equals(TripId('trip_noon')));
    });

    test('10. minute-ticker dependency causes recomputation/refresh consistent with existing upcoming-trips provider', () async {
      final fakeRepo = _FakeTimetableRepository(result: testTimetable);
      final tickerController = StreamController<DateTime>.broadcast();
      final time1 = DateTime(2026, 1, 5, 7, 59);
      final time2 = DateTime(2026, 1, 5, 8, 1); // 08:00 trip departs

      final container = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepo),
          minuteTickerProvider.overrideWith((ref) => tickerController.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(tickerController.close);

      await container.read(timetableProvider.future);

      final query = JourneyQuery(
        boardingStopId: stopAlphaCentral,
        alightingStopId: stopCentralStation,
      );

      final states = <AsyncValue<UpcomingJourneys>>[];
      final sub = container.listen(upcomingJourneysProvider(query), (_, next) {
        states.add(next);
      });
      addTearDown(sub.close);

      tickerController.add(time1);
      await Future.delayed(const Duration(milliseconds: 10));

      tickerController.add(time2);
      await Future.delayed(const Duration(milliseconds: 10));

      // Direct AsyncData -> AsyncData transition without loading flicker
      expect(states.length, equals(2));
      expect(states[0], isA<AsyncData<UpcomingJourneys>>());
      expect(states[0].requireValue.queryTime, equals(time1));
      expect(
        states[0].requireValue.current.length,
        equals(2),
      ); // 8:00 and 12:00

      expect(states[1], isA<AsyncData<UpcomingJourneys>>());
      expect(states[1].requireValue.queryTime, equals(time2));
      expect(
        states[1].requireValue.current.length,
        equals(1),
      ); // only 12:00 remains
    });

    test('11. nextLater result is preserved from domain behavior', () async {
      final fakeRepo = _FakeTimetableRepository(result: testTimetable);
      final tickerController = StreamController<DateTime>.broadcast();
      // Monday 13:00 - all Monday trips have passed. Tuesday trip_tuesday_only runs Tuesday at 09:00.
      final queryTime = DateTime(2026, 1, 5, 13, 0);

      final container = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepo),
          minuteTickerProvider.overrideWith((ref) => tickerController.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(tickerController.close);

      await container.read(timetableProvider.future);

      final query = JourneyQuery(
        boardingStopId: stopAlphaCentral,
        alightingStopId: stopCentralStation,
      );

      final sub = container.listen(upcomingJourneysProvider(query), (_, _) {});
      addTearDown(sub.close);

      tickerController.add(queryTime);
      await Future.delayed(const Duration(milliseconds: 10));

      final asyncValue = container.read(upcomingJourneysProvider(query));
      expect(asyncValue, isA<AsyncData<UpcomingJourneys>>());

      final result = asyncValue.requireValue;
      expect(result.current, isEmpty);
      expect(result.nextLater, isNotEmpty);
      expect(result.nextLater.first.tripId, equals(TripId('trip_morning')));
      expect(
        result.nextLater.first.scheduledDeparture,
        equals(DateTime(2026, 1, 6, 8, 0)),
      );
    });

    test('12. timetable loading/error behavior propagates', () async {
      // 12a. Timetable loading state
      final completer = Completer<Timetable>();
      final loadingTickerController = StreamController<DateTime>();
      loadingTickerController.add(DateTime(2026, 1, 5, 7, 50));
      addTearDown(loadingTickerController.close);

      final containerLoading = ProviderContainer(
        overrides: [
          timetableProvider.overrideWith((ref) => completer.future),
          minuteTickerProvider.overrideWith(
            (ref) => loadingTickerController.stream,
          ),
        ],
      );
      addTearDown(containerLoading.dispose);

      final query = JourneyQuery(
        boardingStopId: stopAlphaCentral,
        alightingStopId: stopCentralStation,
      );
      expect(
        containerLoading.read(upcomingJourneysProvider(query)),
        isA<AsyncLoading<UpcomingJourneys>>(),
      );

      // 12b. Timetable error priority
      final timetableFailure = DataFormatFailure(cause: 'Cannot read JSON');
      final tickerFailure = Exception('Stream failed');
      final tickerErrorController = StreamController<DateTime>.broadcast();
      addTearDown(tickerErrorController.close);

      final containerError = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(
            _FakeTimetableRepository(error: timetableFailure),
          ),
          minuteTickerProvider.overrideWith(
            (ref) => tickerErrorController.stream,
          ),
        ],
      );
      addTearDown(containerError.dispose);

      try {
        await containerError.read(timetableProvider.future);
      } catch (_) {}

      final subErr = containerError.listen(
        upcomingJourneysProvider(query),
        (_, _) {},
      );
      addTearDown(subErr.close);

      tickerErrorController.addError(tickerFailure);
      await Future.delayed(const Duration(milliseconds: 10));

      final errVal = containerError.read(upcomingJourneysProvider(query));
      expect(errVal, isA<AsyncError<UpcomingJourneys>>());
      expect(errVal.error, equals(timetableFailure));

      // 12c. Derivation exception: unknown stop
      final derivationTickerController = StreamController<DateTime>.broadcast();
      addTearDown(derivationTickerController.close);

      final containerUnknownStop = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(
            _FakeTimetableRepository(result: testTimetable),
          ),
          minuteTickerProvider.overrideWith(
            (ref) => derivationTickerController.stream,
          ),
        ],
      );
      addTearDown(containerUnknownStop.dispose);

      await containerUnknownStop.read(timetableProvider.future);

      final queryUnknown = JourneyQuery(
        boardingStopId: StopId('missing_stop'),
        alightingStopId: stopCentralStation,
      );

      final subUnknown = containerUnknownStop.listen(
        upcomingJourneysProvider(queryUnknown),
        (_, _) {},
      );
      addTearDown(subUnknown.close);
      derivationTickerController.add(DateTime(2026, 1, 5, 7, 50));
      await Future.delayed(const Duration(milliseconds: 10));

      final unknownVal = containerUnknownStop.read(
        upcomingJourneysProvider(queryUnknown),
      );
      expect(unknownVal, isA<AsyncError<UpcomingJourneys>>());
      expect(unknownVal.error, isA<ArgumentError>());
      expect(
        (unknownVal.error as ArgumentError).message,
        'Stop not found in timetable',
      );

      // 12d. Derivation exception: same boarding and alighting stop
      final querySame = JourneyQuery(
        boardingStopId: stopAlphaCentral,
        alightingStopId: stopAlphaCentral,
      );

      final subSame = containerUnknownStop.listen(
        upcomingJourneysProvider(querySame),
        (_, _) {},
      );
      addTearDown(subSame.close);
      derivationTickerController.add(DateTime(2026, 1, 5, 7, 50));
      await Future.delayed(const Duration(milliseconds: 10));

      final sameVal = containerUnknownStop.read(
        upcomingJourneysProvider(querySame),
      );
      expect(sameVal, isA<AsyncError<UpcomingJourneys>>());
      expect(sameVal.error, isA<ArgumentError>());
      expect(
        (sameVal.error as ArgumentError).message,
        'Boarding stop and alighting stop must not be the same',
      );
    });

    test('13. logically equal journey-query arguments behave correctly as value keys', () async {
      final fakeRepo = _FakeTimetableRepository(result: testTimetable);
      final tickerController = StreamController<DateTime>.broadcast();
      final queryTime = DateTime(2026, 1, 5, 7, 30);

      final container = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepo),
          minuteTickerProvider.overrideWith((ref) => tickerController.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(tickerController.close);

      await container.read(timetableProvider.future);

      final j1 = JourneyQuery(
        boardingStopId: StopId('stop_alpha_central'),
        alightingStopId: StopId('stop_central_station'),
      );
      final j2 = JourneyQuery(
        boardingStopId: StopId('stop_alpha_central'),
        alightingStopId: StopId('stop_central_station'),
      );

      final sub1 = container.listen(upcomingJourneysProvider(j1), (_, _) {});
      final sub2 = container.listen(upcomingJourneysProvider(j2), (_, _) {});
      addTearDown(sub1.close);
      addTearDown(sub2.close);

      tickerController.add(queryTime);
      await Future.delayed(const Duration(milliseconds: 10));

      final val1 = container.read(upcomingJourneysProvider(j1));
      final val2 = container.read(upcomingJourneysProvider(j2));

      expect(val1, equals(val2));
    });

    test(
      'upcomingJourneysProvider autoDispose cleans up when subscription ends',
      () async {
        final fakeRepo = _FakeTimetableRepository(result: testTimetable);
        final tickerController = StreamController<DateTime>.broadcast();
        final observer = _DisposeObserver();

        final container = ProviderContainer(
          observers: [observer],
          overrides: [
            timetableRepositoryProvider.overrideWithValue(fakeRepo),
            minuteTickerProvider.overrideWith((ref) => tickerController.stream),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(tickerController.close);

        await container.read(timetableProvider.future);

        final query = JourneyQuery(
          boardingStopId: stopAlphaCentral,
          alightingStopId: stopCentralStation,
        );

        final sub = container.listen(
          upcomingJourneysProvider(query),
          (_, _) {},
        );

        expect(
          observer.disposedProviders.contains('upcomingJourneysProvider'),
          isFalse,
        );

        sub.close();
        await Future.delayed(Duration.zero);

        expect(
          observer.disposedProviders.contains('upcomingJourneysProvider'),
          isTrue,
        );
      },
    );
  });
}
