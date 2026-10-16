import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/domain/upcoming_trips_logic.dart';

void main() {
  group('findUpcomingJourneys', () {
    late Timetable timetable;

    setUp(() {
      timetable = Timetable(
        info: TimetableInfo(datasetVersion: '1', isSampleData: true),
        stops: [
          TransitStop(
            id: StopId('stop_A'),
            name: LocalizedText(english: 'Stop A'),
          ),
          TransitStop(
            id: StopId('stop_B'),
            name: LocalizedText(english: 'Stop B'),
          ),
          TransitStop(
            id: StopId('stop_C'),
            name: LocalizedText(english: 'Stop C'),
          ),
          TransitStop(
            id: StopId('stop_D'),
            name: LocalizedText(english: 'Stop D'),
          ),
          TransitStop(
            id: StopId('stop_E'),
            name: LocalizedText(english: 'Stop E'),
          ),
        ],
        routes: [
          TransitRoute(
            id: RouteId('route_1'),
            shortName: LocalizedText(english: 'R1'),
            longName: LocalizedText(english: 'Route 1'),
          ),
        ],
        trips: [
          // Trip 1: Morning trip, departs A at 08:00, arrives B at 08:15, arrives C at 08:30 (final stop C)
          ScheduledTrip(
            id: TripId('trip_1'),
            routeId: RouteId('route_1'),
            serviceDays: const ServiceDays(monday: true, tuesday: true),
            stopTimes: [
              StopTime(
                stopId: StopId('stop_A'),
                arrivalTime: ServiceTime(hour: 8, minute: 0),
                departureTime: ServiceTime(hour: 8, minute: 0),
              ),
              StopTime(
                stopId: StopId('stop_B'),
                arrivalTime: ServiceTime(hour: 8, minute: 15),
                departureTime: ServiceTime(hour: 8, minute: 15),
              ),
              StopTime(
                stopId: StopId('stop_C'),
                arrivalTime: ServiceTime(hour: 8, minute: 30),
                departureTime: ServiceTime(hour: 8, minute: 30),
              ),
            ],
          ),
          // Trip 2: Late night trip, departs A at 23:45, departs B at 24:00, departs C at 24:15, arrives D at 24:30
          ScheduledTrip(
            id: TripId('trip_2'),
            routeId: RouteId('route_1'),
            serviceDays: const ServiceDays(monday: true),
            stopTimes: [
              StopTime(
                stopId: StopId('stop_A'),
                arrivalTime: ServiceTime(hour: 23, minute: 45),
                departureTime: ServiceTime(hour: 23, minute: 45),
              ),
              StopTime(
                stopId: StopId('stop_B'),
                arrivalTime: ServiceTime(hour: 24, minute: 0),
                departureTime: ServiceTime(hour: 24, minute: 0),
              ),
              StopTime(
                stopId: StopId('stop_C'),
                arrivalTime: ServiceTime(hour: 24, minute: 15),
                departureTime: ServiceTime(hour: 24, minute: 15),
              ),
              StopTime(
                stopId: StopId('stop_D'),
                arrivalTime: ServiceTime(hour: 24, minute: 30),
                departureTime: ServiceTime(hour: 24, minute: 30),
              ),
            ],
          ),
          // Trip 3: Branch trip, departs A at 09:00, arrives E at 09:30 (does not serve B, C, or D)
          ScheduledTrip(
            id: TripId('trip_branch'),
            routeId: RouteId('route_1'),
            serviceDays: const ServiceDays(monday: true),
            stopTimes: [
              StopTime(
                stopId: StopId('stop_A'),
                arrivalTime: ServiceTime(hour: 9, minute: 0),
                departureTime: ServiceTime(hour: 9, minute: 0),
              ),
              StopTime(
                stopId: StopId('stop_E'),
                arrivalTime: ServiceTime(hour: 9, minute: 30),
                departureTime: ServiceTime(hour: 9, minute: 30),
              ),
            ],
          ),
          // Trip 4: Zero duration fixture between A and B, departs A at 10:00, arrives B at 10:00, departs B at 10:00, arrives C at 10:15
          ScheduledTrip(
            id: TripId('trip_zero'),
            routeId: RouteId('route_1'),
            serviceDays: const ServiceDays(monday: true),
            stopTimes: [
              StopTime(
                stopId: StopId('stop_A'),
                arrivalTime: ServiceTime(hour: 10, minute: 0),
                departureTime: ServiceTime(hour: 10, minute: 0),
              ),
              StopTime(
                stopId: StopId('stop_B'),
                arrivalTime: ServiceTime(hour: 10, minute: 0),
                departureTime: ServiceTime(hour: 10, minute: 0),
              ),
              StopTime(
                stopId: StopId('stop_C'),
                arrivalTime: ServiceTime(hour: 10, minute: 15),
                departureTime: ServiceTime(hour: 10, minute: 15),
              ),
            ],
          ),
        ],
      );
    });

    // 2026-10-12 is a Monday.

    test('direct downstream journey is returned', () {
      final now = DateTime(2026, 10, 12, 7, 50);
      final result = findUpcomingJourneys(
        boardingStopId: StopId('stop_A'),
        alightingStopId: StopId('stop_B'),
        timetable: timetable,
        now: now,
      );

      expect(result.current.isNotEmpty, isTrue);
      expect(result.current.first.tripId, TripId('trip_1'));
      expect(result.current.first.boardingStopId, StopId('stop_A'));
      expect(result.current.first.alightingStopId, StopId('stop_B'));
      expect(
        result.current.first.scheduledDeparture,
        DateTime(2026, 10, 12, 8, 0),
      );
      expect(
        result.current.first.scheduledArrival,
        DateTime(2026, 10, 12, 8, 15),
      );
      expect(
        result.current.first.scheduledDuration,
        const Duration(minutes: 15),
      );
    });

    test('reverse-direction request is excluded', () {
      // Query B to A when trips run A -> B -> C
      final now = DateTime(2026, 10, 12, 7, 50);
      final result = findUpcomingJourneys(
        boardingStopId: StopId('stop_B'),
        alightingStopId: StopId('stop_A'),
        timetable: timetable,
        now: now,
      );

      expect(result.current, isEmpty);
      expect(result.nextLater, isEmpty);
    });

    test('same-stop request throws ArgumentError', () {
      final now = DateTime(2026, 10, 12, 7, 50);
      expect(
        () => findUpcomingJourneys(
          boardingStopId: StopId('stop_A'),
          alightingStopId: StopId('stop_A'),
          timetable: timetable,
          now: now,
        ),
        throwsArgumentError,
      );
    });

    test('unknown boarding throws exact ArgumentError', () {
      final now = DateTime(2026, 10, 12, 7, 50);
      expect(
        () => findUpcomingJourneys(
          boardingStopId: StopId('unknown_stop'),
          alightingStopId: StopId('stop_B'),
          timetable: timetable,
          now: now,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Stop not found in timetable',
          ),
        ),
      );
    });

    test('unknown alighting throws exact ArgumentError', () {
      final now = DateTime(2026, 10, 12, 7, 50);
      expect(
        () => findUpcomingJourneys(
          boardingStopId: StopId('stop_A'),
          alightingStopId: StopId('unknown_stop'),
          timetable: timetable,
          now: now,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Stop not found in timetable',
          ),
        ),
      );
    });

    test('requested alighting can be intermediate while tripHeadsign remains final stop', () {
      // Trip 1 runs A -> B -> C. Request journey from A to B.
      final now = DateTime(2026, 10, 12, 7, 50);
      final result = findUpcomingJourneys(
        boardingStopId: StopId('stop_A'),
        alightingStopId: StopId('stop_B'),
        timetable: timetable,
        now: now,
      );

      final journey = result.current.first;
      expect(journey.alightingStopId, StopId('stop_B'));
      expect(journey.alightingStopName, LocalizedText(english: 'Stop B'));
      // Headsign must remain final stop of the trip (Stop C)
      expect(journey.tripHeadsign, LocalizedText(english: 'Stop C'));
    });

    test('scheduledArrival uses alighting arrivalTime', () {
      // For A -> B on Trip 1, scheduledArrival is 08:15, not 08:30 (trip final arrival)
      final now = DateTime(2026, 10, 12, 7, 50);
      final result = findUpcomingJourneys(
        boardingStopId: StopId('stop_A'),
        alightingStopId: StopId('stop_B'),
        timetable: timetable,
        now: now,
      );

      expect(
        result.current.first.scheduledArrival,
        DateTime(2026, 10, 12, 8, 15),
      );
    });

    test('scheduledDeparture uses boarding departureTime', () {
      // For B -> C on Trip 1, scheduledDeparture is 08:15, not 08:00 (trip start departure)
      final now = DateTime(2026, 10, 12, 7, 50);
      final result = findUpcomingJourneys(
        boardingStopId: StopId('stop_B'),
        alightingStopId: StopId('stop_C'),
        timetable: timetable,
        now: now,
      );

      expect(
        result.current.first.scheduledDeparture,
        DateTime(2026, 10, 12, 8, 15),
      );
      expect(
        result.current.first.scheduledArrival,
        DateTime(2026, 10, 12, 8, 30),
      );
    });

    test('current-minute departure is included', () {
      final now = DateTime(2026, 10, 12, 8, 0);
      final result = findUpcomingJourneys(
        boardingStopId: StopId('stop_A'),
        alightingStopId: StopId('stop_C'),
        timetable: timetable,
        now: now,
      );

      expect(result.current.isNotEmpty, isTrue);
      expect(result.current.first.tripId, TripId('trip_1'));
      expect(
        result.current.first.scheduledDeparture,
        DateTime(2026, 10, 12, 8, 0),
      );
    });

    test('passed boarding departure is excluded', () {
      final now = DateTime(2026, 10, 12, 8, 1);
      final result = findUpcomingJourneys(
        boardingStopId: StopId('stop_A'),
        alightingStopId: StopId('stop_C'),
        timetable: timetable,
        now: now,
      );

      // Trip 1 at 08:00 is passed. Next is Trip zero at 10:00.
      expect(result.current.isNotEmpty, isTrue);
      expect(result.current.first.tripId, TripId('trip_zero'));
      expect(result.current.any((j) => j.tripId == TripId('trip_1')), isFalse);
    });

    test('terminal boarding remains excluded through shared core', () {
      // Stop C is final stop for Trip 1. Passenger cannot board at C.
      final now = DateTime(2026, 10, 12, 8, 0);
      final result = findUpcomingJourneys(
        boardingStopId: StopId('stop_C'),
        alightingStopId: StopId('stop_D'),
        timetable: timetable,
        now: now,
      );

      // Only Trip 2 serves C non-terminally towards D (at 24:15)
      expect(result.current.length, 1);
      expect(result.current.first.tripId, TripId('trip_2'));
    });

    test('yesterday service date with >=24:00 works for journeys', () {
      // Query on Tuesday 00:05 (2026-10-13 00:05).
      // Trip 2 operated on Monday service day, departs C at 24:15 (Tuesday 00:15), arrives D at 24:30.
      final now = DateTime(2026, 10, 13, 0, 5);
      final result = findUpcomingJourneys(
        boardingStopId: StopId('stop_C'),
        alightingStopId: StopId('stop_D'),
        timetable: timetable,
        now: now,
      );

      expect(result.current.isNotEmpty, isTrue);
      expect(result.current.first.tripId, TripId('trip_2'));
      expect(
        result.current.first.scheduledDeparture,
        DateTime(2026, 10, 13, 0, 15),
      );
      expect(
        result.current.first.scheduledArrival,
        DateTime(2026, 10, 13, 0, 30),
      );
      expect(result.current.first.serviceDate, DateTime(2026, 10, 12));
    });

    test(
      'nextLater is only populated when eligible current journeys are empty',
      () {
        // Query on Wednesday 08:00 (2026-10-14 08:00).
        // Trip 1 runs Mon, Tue. So current is empty. nextLater has next Monday.
        final now = DateTime(2026, 10, 14, 8, 0);
        final result = findUpcomingJourneys(
          boardingStopId: StopId('stop_A'),
          alightingStopId: StopId('stop_C'),
          timetable: timetable,
          now: now,
        );

        expect(result.current, isEmpty);
        expect(result.nextLater.isNotEmpty, isTrue);
        expect(result.nextLater.first.tripId, TripId('trip_1'));
        expect(
          result.nextLater.first.scheduledDeparture,
          DateTime(2026, 10, 19, 8, 0),
        );
      },
    );

    test('boarding-only current trip that does not reach requested alighting stop does not suppress nextLater', () {
      // On Monday at 08:50, Trip_branch departs A at 09:00, but goes to E (not C).
      // No more trips from A to C on Monday (Trip 1 was 08:00, Trip zero was 10:00... wait, let's query at 10:05).
      // At 10:05 on Monday, Trip 1 (08:00) and Trip zero (10:00) have passed.
      // Trip 2 (23:45) departs A and goes to C!
      // But suppose we query for A -> E on Monday at 09:35.
      // Trip_branch (09:00) was the ONLY trip to E on Monday!
      // Next trip to E is next Monday.
      // Today (Monday 09:35), Trip zero departs A at 10:00 and Trip 2 departs A at 23:45.
      // BOTH Trip zero and Trip 2 serve Stop A TODAY, but NEITHER serves Stop E!
      // Therefore, current journeys from A to E MUST be empty, and nextLater MUST find next Monday's Trip_branch!
      // The current boarding-only trips (zero and 2) must NOT suppress nextLater!
      final now = DateTime(2026, 10, 12, 9, 35);
      final result = findUpcomingJourneys(
        boardingStopId: StopId('stop_A'),
        alightingStopId: StopId('stop_E'),
        timetable: timetable,
        now: now,
      );

      expect(result.current, isEmpty);
      expect(result.nextLater.isNotEmpty, isTrue);
      expect(result.nextLater.first.tripId, TripId('trip_branch'));
      expect(
        result.nextLater.first.scheduledDeparture,
        DateTime(2026, 10, 19, 9, 0),
      );
    });

    test('deterministic chronological ordering is preserved', () {
      // On Monday 07:00, departures from A to C are:
      // Trip 1 at 08:00, Trip zero at 10:00, Trip 2 at 23:45.
      final now = DateTime(2026, 10, 12, 7, 0);
      final result = findUpcomingJourneys(
        boardingStopId: StopId('stop_A'),
        alightingStopId: StopId('stop_C'),
        timetable: timetable,
        now: now,
      );

      expect(result.current.length, 3);
      expect(result.current[0].tripId, TripId('trip_1'));
      expect(result.current[1].tripId, TripId('trip_zero'));
      expect(result.current[2].tripId, TripId('trip_2'));
    });

    test('limit is applied consistently', () {
      final now = DateTime(2026, 10, 12, 7, 0);
      final result = findUpcomingJourneys(
        boardingStopId: StopId('stop_A'),
        alightingStopId: StopId('stop_C'),
        timetable: timetable,
        now: now,
        limit: 2,
      );

      expect(result.current.length, 2);
      expect(result.current[0].tripId, TripId('trip_1'));
      expect(result.current[1].tripId, TripId('trip_zero'));
    });

    test('zero-duration downstream journey is accepted and returned', () {
      // Trip zero departs A at 10:00 and arrives B at 10:00 (zero duration)
      final now = DateTime(2026, 10, 12, 9, 50);
      final result = findUpcomingJourneys(
        boardingStopId: StopId('stop_A'),
        alightingStopId: StopId('stop_B'),
        timetable: timetable,
        now: now,
      );

      final zeroJourney = result.current.firstWhere(
        (j) => j.tripId == TripId('trip_zero'),
      );
      expect(zeroJourney.scheduledDeparture, DateTime(2026, 10, 12, 10, 0));
      expect(zeroJourney.scheduledArrival, DateTime(2026, 10, 12, 10, 0));
      expect(zeroJourney.scheduledDuration, Duration.zero);
    });
  });
}
