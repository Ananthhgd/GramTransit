import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/logging/app_logger.dart';
import 'package:gramtransit_passenger/core/logging/logging_providers.dart';
import 'package:gramtransit_passenger/core/time/time_providers.dart';
import 'package:gramtransit_passenger/features/transit/data/bundled_timetable_repository.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/timetable_repository.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/domain/trip_occurrence.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

class FakeTimetableRepository implements TimetableRepository {
  final Timetable? result;
  final Object? error;
  final StackTrace? stackTrace;
  int callCount = 0;

  FakeTimetableRepository({this.result, this.error, this.stackTrace});

  @override
  Future<Timetable> loadTimetable() async {
    callCount++;
    if (error != null) {
      if (stackTrace != null) {
        Error.throwWithStackTrace(error!, stackTrace!);
      }
      throw error!;
    }
    return result!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Timetable dummyTimetable;
  late StopId stopIdA;

  setUp(() {
    stopIdA = StopId('stop_A');
    final stopIdB = StopId('stop_B');
    final routeId1 = RouteId('route_1');

    dummyTimetable = Timetable(
      info: TimetableInfo(datasetVersion: '1', isSampleData: true),
      stops: [
        TransitStop(
          id: stopIdA,
          name: LocalizedText(english: 'A'),
        ),
        TransitStop(
          id: stopIdB,
          name: LocalizedText(english: 'B'),
        ),
      ],
      routes: [
        TransitRoute(
          id: routeId1,
          shortName: LocalizedText(english: '1'),
          longName: LocalizedText(english: 'One'),
        ),
      ],
      trips: [
        ScheduledTrip(
          id: TripId('trip_1'),
          routeId: routeId1,
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
              stopId: stopIdA,
              arrivalTime: ServiceTime(hour: 8, minute: 0),
              departureTime: ServiceTime(hour: 8, minute: 0),
            ),
            StopTime(
              stopId: stopIdB,
              arrivalTime: ServiceTime(hour: 8, minute: 10),
              departureTime: ServiceTime(hour: 8, minute: 10),
            ),
          ],
        ),
      ],
    );
  });

  group('P4 Providers', () {
    test(
      '1. timetableRepositoryProvider builds a BundledTimetableRepository',
      () {
        final container = ProviderContainer(
          overrides: [appLoggerProvider.overrideWithValue(const AppLogger())],
        );
        final repo = container.read(timetableRepositoryProvider);
        expect(repo, isA<BundledTimetableRepository>());
      },
    );

    test(
      '2. timetableProvider exposes fake Timetable and memoizes loadTimetable',
      () async {
        final fakeRepo = FakeTimetableRepository(result: dummyTimetable);
        final container = ProviderContainer(
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );

        final val1 = await container.read(timetableProvider.future);
        expect(val1, dummyTimetable);
        expect(fakeRepo.callCount, 1);

        final val2 = await container.read(timetableProvider.future);
        expect(val2, dummyTimetable);
        expect(fakeRepo.callCount, 1);
      },
    );

    test('3. Timetable failure / no Riverpod retry', () async {
      final stackTrace = StackTrace.current;
      final exception = DataFormatFailure(
        cause: 'format issue',
        stackTrace: stackTrace,
      );
      final fakeRepo = FakeTimetableRepository(
        error: exception,
        stackTrace: stackTrace,
      );
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );

      var caught = false;
      try {
        await container.read(timetableProvider.future);
      } catch (e) {
        expect(e, exception);
        caught = true;
      }
      expect(caught, isTrue);

      final asyncValue = container.read(timetableProvider);
      expect(asyncValue, isA<AsyncError>());
      expect(asyncValue.error, exception);

      // Verify it doesn't automatically retry
      expect(fakeRepo.callCount, 1);
    });

    test('4. Real bundled asset timetable load', () async {
      final container = ProviderContainer(
        overrides: [appLoggerProvider.overrideWithValue(const AppLogger())],
      );
      final timetable = await container.read(timetableProvider.future);
      expect(timetable.info.datasetVersion, isNotEmpty);
      expect(timetable.info.isSampleData, isTrue);
    });

    test('5. Upcoming loading: timetable', () {
      final fakeRepo = FakeTimetableRepository(
        result: dummyTimetable,
      ); // Will complete asynchronously
      final streamController = StreamController<DateTime>();
      streamController.add(DateTime(2026, 1, 1, 7, 50));

      final container = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepo),
          minuteTickerProvider.overrideWith((ref) => streamController.stream),
        ],
      );

      final asyncValue = container.read(upcomingTripsProvider(stopIdA));
      expect(asyncValue, isA<AsyncLoading<UpcomingTrips>>());
    });

    test('6. Upcoming loading: ticker', () async {
      final fakeRepo = FakeTimetableRepository(result: dummyTimetable);
      final streamController = StreamController<DateTime>();

      final container = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepo),
          minuteTickerProvider.overrideWith((ref) => streamController.stream),
        ],
      );

      await container.read(timetableProvider.future);

      final asyncValue = container.read(upcomingTripsProvider(stopIdA));
      expect(asyncValue, isA<AsyncLoading<UpcomingTrips>>());
    });

    test('7. Upcoming data', () async {
      final fakeRepo = FakeTimetableRepository(result: dummyTimetable);
      final streamController = StreamController<DateTime>.broadcast();
      final initialTime = DateTime(2026, 1, 1, 7, 50);

      final container = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepo),
          minuteTickerProvider.overrideWith((ref) => streamController.stream),
        ],
      );

      await container.read(timetableProvider.future);

      // We must listen for the provider to react to the stream
      final subscription = container.listen(
        upcomingTripsProvider(stopIdA),
        (_, _) {},
      );

      streamController.add(initialTime);
      await Future.delayed(const Duration(milliseconds: 10));

      final asyncValue = container.read(upcomingTripsProvider(stopIdA));
      expect(asyncValue, isA<AsyncData<UpcomingTrips>>());
      expect(asyncValue.requireValue.current.length, 1);
      expect(asyncValue.requireValue.queryTime, initialTime);

      subscription.close();
    });

    test(
      '8. Reactive recomputation & 9. REQUIRED no-flicker behavior',
      () async {
        final fakeRepo = FakeTimetableRepository(result: dummyTimetable);
        final streamController = StreamController<DateTime>.broadcast();
        final initialTime = DateTime(2026, 1, 1, 7, 50);
        final nextTime = DateTime(2026, 1, 1, 7, 51);

        final container = ProviderContainer(
          overrides: [
            timetableRepositoryProvider.overrideWithValue(fakeRepo),
            minuteTickerProvider.overrideWith((ref) => streamController.stream),
          ],
        );

        await container.read(timetableProvider.future);

        final states = <AsyncValue<UpcomingTrips>>[];
        final subscription = container.listen(upcomingTripsProvider(stopIdA), (
          previous,
          next,
        ) {
          states.add(next);
        });

        streamController.add(initialTime);
        await Future.delayed(const Duration(milliseconds: 10));

        streamController.add(nextTime);
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify no-flicker: state transitions directly from one AsyncData to the next
        expect(states.length, 2);
        expect(states[0], isA<AsyncData<UpcomingTrips>>());
        expect(states[0].requireValue.queryTime, initialTime);

        expect(states[1], isA<AsyncData<UpcomingTrips>>());
        expect(states[1].requireValue.queryTime, nextTime);

        subscription.close();
      },
    );

    test('10. Timetable error priority', () async {
      final exception = Exception('Repo failed');
      final fakeRepo = FakeTimetableRepository(error: exception);
      final streamController = StreamController<DateTime>();
      streamController.add(DateTime(2026, 1, 1, 7, 50));

      final container = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepo),
          minuteTickerProvider.overrideWith((ref) => streamController.stream),
        ],
      );

      // Await repo failure
      try {
        await container.read(timetableProvider.future);
      } catch (_) {}

      final asyncValue = container.read(upcomingTripsProvider(stopIdA));
      expect(asyncValue, isA<AsyncError<UpcomingTrips>>());
      expect(asyncValue.error, exception);
    });

    test('11. Ticker error', () async {
      final fakeRepo = FakeTimetableRepository(result: dummyTimetable);
      final streamController = StreamController<DateTime>.broadcast();
      final exception = Exception('Stream failed');

      final container = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepo),
          minuteTickerProvider.overrideWith((ref) => streamController.stream),
        ],
      );

      await container.read(timetableProvider.future);

      final subscription = container.listen(
        upcomingTripsProvider(stopIdA),
        (_, _) {},
      );

      streamController.addError(exception);
      await Future.delayed(const Duration(milliseconds: 10));

      final asyncValue = container.read(upcomingTripsProvider(stopIdA));
      expect(asyncValue, isA<AsyncError<UpcomingTrips>>());
      expect(asyncValue.error, exception);

      subscription.close();
    });

    test('12. Derivation exception', () async {
      final fakeRepo = FakeTimetableRepository(result: dummyTimetable);
      final streamController = StreamController<DateTime>();
      streamController.add(DateTime(2026, 1, 1, 7, 50));

      final container = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepo),
          minuteTickerProvider.overrideWith((ref) => streamController.stream),
        ],
      );

      await container.read(timetableProvider.future);

      // Use a StopId that doesn't exist in the dummy timetable
      final missingStopId = StopId('stop_MISSING');

      // Listen to trigger stream subscription and wait for propagation
      final sub = container.listen(
        upcomingTripsProvider(missingStopId),
        (_, _) {},
      );
      await Future.delayed(const Duration(milliseconds: 10));

      final asyncValue = container.read(upcomingTripsProvider(missingStopId));
      sub.close();

      expect(asyncValue, isA<AsyncError<UpcomingTrips>>());
      expect(asyncValue.error, isA<ArgumentError>());
      expect(
        (asyncValue.error as ArgumentError).message,
        'Stop not found in timetable',
      );
    });

    test('13. Family/value equality', () async {
      final fakeRepo = FakeTimetableRepository(result: dummyTimetable);
      final streamController = StreamController<DateTime>.broadcast();

      final container = ProviderContainer(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepo),
          minuteTickerProvider.overrideWith((ref) => streamController.stream),
        ],
      );

      final stopA1 = StopId('stop_A');
      final stopA2 = StopId(
        'stop_A',
      ); // Independently constructed, equals by value
      final stopB = StopId('stop_B');

      // They should read exactly the same provider reference internally
      final refA1 = container.listen(upcomingTripsProvider(stopA1), (_, _) {});
      final refA2 = container.listen(upcomingTripsProvider(stopA2), (_, _) {});
      final refB = container.listen(upcomingTripsProvider(stopB), (_, _) {});

      final valA1 = container.read(upcomingTripsProvider(stopA1));
      final valA2 = container.read(upcomingTripsProvider(stopA2));

      // As long as they haven't been disposed, reading from stopA1 or stopA2
      // retrieves the state of the identical underlying provider element.
      expect(valA1, valA2);
      // If we used identical(valA1, valA2) it wouldn't be identical since they are AsyncValues, but Riverpod guarantees
      // the family key maps to the same element.

      refA1.close();
      refA2.close();
      refB.close();
    });

    test('14. autoDispose', () async {
      final fakeRepo = FakeTimetableRepository(result: dummyTimetable);
      final streamController = StreamController<DateTime>.broadcast();
      streamController.add(DateTime(2026, 1, 1, 7, 50));

      final observer = _DisposeObserver();

      final container = ProviderContainer(
        observers: [observer],
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepo),
          minuteTickerProvider.overrideWith((ref) => streamController.stream),
        ],
      );

      await container.read(timetableProvider.future);

      final subscription = container.listen(
        upcomingTripsProvider(stopIdA),
        (_, _) {},
      );

      expect(observer.didDispose, isFalse);

      subscription.close();
      await Future.delayed(
        Duration.zero,
      ); // allow Riverpod autoDispose to trigger

      expect(observer.didDispose, isTrue);
    });
  });
}

final class _DisposeObserver extends ProviderObserver {
  bool didDispose = false;

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    if (context.provider.name == 'upcomingTripsProvider') {
      didDispose = true;
    }
  }
}
