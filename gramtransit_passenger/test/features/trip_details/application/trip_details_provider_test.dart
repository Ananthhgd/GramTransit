import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';
import 'package:gramtransit_passenger/features/trip_details/application/trip_details_provider.dart';

import '../trip_details_test_support.dart';

void main() {
  group('tripDetailsProvider', () {
    test('1. known trip resolves correctly with full data', () async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      // Trigger timetable loading
      await container.read(timetableProvider.future);

      final tripAsync = container.read(tripDetailsProvider(TripId('trip_1')));
      expect(tripAsync, isA<AsyncData<TripDetails?>>());
      final details = tripAsync.value!;
      expect(details.tripId, equals(TripId('trip_1')));
      expect(details.stops.length, equals(3));
    });

    test('2. route names correct', () async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final details = container
          .read(tripDetailsProvider(TripId('trip_1')))
          .value!;
      expect(details.routeShortName.english, equals('101'));
      expect(
        details.routeLongName.english,
        equals('City Center to North Station'),
      );
    });

    test('3. service days preserved', () async {
      final timetable = createTripDetailsTestTimetable(
        trips: [
          ScheduledTrip(
            id: TripId('trip_weekday_only'),
            routeId: RouteId('route_1'),
            serviceDays: const ServiceDays(
              monday: true,
              tuesday: true,
              wednesday: true,
              thursday: true,
              friday: true,
              saturday: false,
              sunday: false,
            ),
            stopTimes: [
              StopTime(
                stopId: StopId('stop_1'),
                arrivalTime: ServiceTime(hour: 9, minute: 0),
                departureTime: ServiceTime(hour: 9, minute: 5),
              ),
              StopTime(
                stopId: StopId('stop_2'),
                arrivalTime: ServiceTime(hour: 9, minute: 30),
                departureTime: ServiceTime(hour: 9, minute: 35),
              ),
            ],
          ),
        ],
      );
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final details = container
          .read(tripDetailsProvider(TripId('trip_weekday_only')))
          .value!;
      expect(details.serviceDays.monday, isTrue);
      expect(details.serviceDays.friday, isTrue);
      expect(details.serviceDays.saturday, isFalse);
      expect(details.serviceDays.sunday, isFalse);
    });

    test('4. stops retain trip order', () async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final details = container
          .read(tripDetailsProvider(TripId('trip_1')))
          .value!;
      expect(details.stops[0].stopName.english, equals('City Center'));
      expect(details.stops[1].stopName.english, equals('Market Square'));
      expect(details.stops[2].stopName.english, equals('North Station'));
    });

    test('5. first/intermediate/last positions correct', () async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final details = container
          .read(tripDetailsProvider(TripId('trip_1')))
          .value!;
      expect(details.stops[0].position, equals(TripStopPosition.first));
      expect(details.stops[1].position, equals(TripStopPosition.intermediate));
      expect(details.stops[2].position, equals(TripStopPosition.last));
    });

    test('6. unknown TripId -> AsyncData(null)', () async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final tripAsync = container.read(
        tripDetailsProvider(TripId('non_existent_trip')),
      );
      expect(tripAsync, isA<AsyncData<TripDetails?>>());
      expect(tripAsync.value, isNull);
    });

    test('7. timetable error propagates', () async {
      final expectedError = DataFormatFailure(cause: 'Corrupt file');
      final fakeRepo = FakeTripDetailsTimetableRepository(error: expectedError);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      try {
        await container.read(timetableProvider.future);
      } catch (_) {}

      final tripAsync = container.read(tripDetailsProvider(TripId('trip_1')));
      expect(tripAsync, isA<AsyncError<TripDetails?>>());
      expect(tripAsync.error, equals(expectedError));
    });

    test('8a. dangling route reference produces DataFormatFailure', () async {
      final timetable = createTripDetailsTestTimetable(
        routes: [], // No routes in timetable
      );
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final tripAsync = container.read(tripDetailsProvider(TripId('trip_1')));
      expect(tripAsync, isA<AsyncError<TripDetails?>>());
      expect(tripAsync.error, isA<DataFormatFailure>());
      expect(
        (tripAsync.error as DataFormatFailure).cause,
        contains('Route route_1'),
      );
    });

    test('8b. dangling stop reference produces DataFormatFailure', () async {
      final timetable = createTripDetailsTestTimetable(
        stops: [
          // Missing stop_2 and stop_3
          TransitStop(
            id: StopId('stop_1'),
            name: LocalizedText(english: 'City Center'),
          ),
        ],
      );
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(timetableProvider.future);

      final tripAsync = container.read(tripDetailsProvider(TripId('trip_1')));
      expect(tripAsync, isA<AsyncError<TripDetails?>>());
      expect(tripAsync.error, isA<DataFormatFailure>());
      expect(
        (tripAsync.error as DataFormatFailure).cause,
        contains('Stop stop_2'),
      );
    });

    test('9. timetable loading state preserves AsyncLoading', () {
      final completer = Completer<Timetable>();
      final fakeRepo = FakeTripDetailsTimetableRepository(completer: completer);
      final container = ProviderContainer(
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final tripAsync = container.read(tripDetailsProvider(TripId('trip_1')));
      expect(tripAsync, isA<AsyncLoading<TripDetails?>>());

      completer.complete(createTripDetailsTestTimetable());
    });
  });
}
