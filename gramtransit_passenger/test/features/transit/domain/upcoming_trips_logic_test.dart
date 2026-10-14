import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/domain/upcoming_trips_logic.dart';

void main() {
  group('findUpcomingTrips', () {
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
        ],
        routes: [
          TransitRoute(
            id: RouteId('route_1'),
            shortName: LocalizedText(english: 'R1'),
            longName: LocalizedText(english: 'Route 1'),
          ),
        ],
        trips: [
          // Trip 1: Morning trip, departs A at 08:00, arrives C at 08:30 (terminates at C)
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
          // Trip 2: Late night trip, departs A at 23:45, departs C at 24:15, arrives D at 24:30 (terminates at D)
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
        ],
      );
    });

    // 2026-10-12 is a Monday.

    test('normal same-day upcoming service populates current', () {
      final now = DateTime(2026, 10, 12, 7, 50); // Mon 07:50
      final result = findUpcomingTrips(
        stopId: StopId('stop_A'),
        timetable: timetable,
        now: now,
      );

      expect(result.current.isNotEmpty, isTrue);
      expect(result.nextLater, isEmpty); // Because current is populated
      expect(result.current.first.tripId, TripId('trip_1'));
      expect(
        result.current.first.scheduledDeparture,
        DateTime(2026, 10, 12, 8, 0),
      );
    });

    test('upcoming departure at queried stop populates current when departure >= query minute', () {
      // Query at Stop B. The bus departed A at 08:00, departs B at 08:15.
      // Current time is 08:10. The departure at Stop B is upcoming.
      final now = DateTime(2026, 10, 12, 8, 10);
      final result = findUpcomingTrips(
        stopId: StopId('stop_B'),
        timetable: timetable,
        now: now,
        limit: 2,
      );

      expect(result.current.length, 2); // trip_1 at 08:15 and trip_2 at 24:00
      expect(result.nextLater, isEmpty);
      expect(result.current.first.tripId, TripId('trip_1'));
      expect(
        result.current.first.scheduledDeparture,
        DateTime(2026, 10, 12, 8, 15),
      );
    });

    test('queried terminal stop does not return terminating trip as a boarding departure', () {
      // Stop C is the terminal/final stop for Trip 1 (08:30 arrival/departure).
      // Query at Stop C at 08:30 (when Trip 1 terminates).
      final now = DateTime(2026, 10, 12, 8, 30);
      final result = findUpcomingTrips(
        stopId: StopId('stop_C'),
        timetable: timetable,
        now: now,
      );

      // Trip 1 terminates at Stop C, so it must NOT appear in current.
      expect(
        result.current.any((occ) => occ.tripId == TripId('trip_1')),
        isFalse,
      );
      // Trip 2 serves Stop C non-terminally (departs 24:15 towards Stop D), so current has Trip 2.
      expect(result.current.first.tripId, TripId('trip_2'));
      // nextLater must NOT reintroduce Trip 1 terminating occurrence.
      expect(
        result.nextLater.any((occ) => occ.tripId == TripId('trip_1')),
        isFalse,
      );

      // Additionally query Stop D (terminal stop for Trip 2) on Monday night:
      final resultAtD = findUpcomingTrips(
        stopId: StopId('stop_D'),
        timetable: timetable,
        now: DateTime(2026, 10, 12, 23, 0),
      );
      // Stop D is only a terminal stop in this timetable, so both current and nextLater must be empty.
      expect(resultAtD.current, isEmpty);
      expect(resultAtD.nextLater, isEmpty);
    });

    test('trip ending before now is not treated as current/relevant', () {
      // Query at Stop B at 08:40. Trip 1 departed B at 08:15. It should NOT be relevant.
      final now = DateTime(2026, 10, 12, 8, 40);
      final result = findUpcomingTrips(
        stopId: StopId('stop_B'),
        timetable: timetable,
        now: now,
      );

      // Should find Trip 2 instead, because Trip 1 is fully in the past.
      expect(result.current.first.tripId, TripId('trip_2'));
      expect(result.nextLater, isEmpty);
    });

    test('after-midnight ServiceTime belonging to yesterdays service day is correctly considered', () {
      // Query at Stop C on TUESDAY at 00:05 (2026-10-13 00:05).
      // Trip 2 operates on MONDAY service day, and departs Stop C at 24:15 (Tuesday 00:15) towards Stop D.
      // Stop C is non-terminal for Trip 2.
      final now = DateTime(2026, 10, 13, 0, 5); // Tuesday 00:05
      final result = findUpcomingTrips(
        stopId: StopId('stop_C'),
        timetable: timetable,
        now: now,
      );

      expect(result.current.isNotEmpty, isTrue);
      expect(result.current.first.tripId, TripId('trip_2'));
      expect(
        result.current.first.scheduledDeparture,
        DateTime(2026, 10, 13, 0, 15),
      );
      expect(result.nextLater, isEmpty);
    });

    test('non-terminal departure scheduled exactly at queryTime minute is included', () {
      // Trip 1 departs Stop A at exactly 08:00. Query now is 08:00.
      final now = DateTime(2026, 10, 12, 8, 0);
      final result = findUpcomingTrips(
        stopId: StopId('stop_A'),
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

    test('sub-minute query time includes departure in the same minute', () {
      // Trip 1 departs Stop A at 08:00.
      // Query now carries seconds and milliseconds (08:00:15.500).
      final now = DateTime(2026, 10, 12, 8, 0, 15, 500);
      final result = findUpcomingTrips(
        stopId: StopId('stop_A'),
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

    test('non-terminal scheduled departure one minute before query minute is excluded even if trip in progress', () {
      // Trip 1 departs Stop A at 08:00 and arrives Stop C at 08:30.
      // At 08:01, the departure at Stop A has already passed by 1 minute,
      // even though the trip is still active downstream until 08:30.
      final now = DateTime(2026, 10, 12, 8, 1);
      final result = findUpcomingTrips(
        stopId: StopId('stop_A'),
        timetable: timetable,
        now: now,
      );

      // Trip 1 (08:00 departure at Stop A) must NOT be returned.
      // Next at Stop A is Trip 2 at 23:45.
      expect(result.current.isNotEmpty, isTrue);
      expect(result.current.first.tripId, TripId('trip_2'));
      expect(
        result.current.any((occ) => occ.tripId == TripId('trip_1')),
        isFalse,
      );
    });

    test('service-day filtering & nextLater finds a valid service within the next 7 days', () {
      // Query on Wednesday 08:00 (2026-10-14 08:00).
      // Trip 1 runs Mon, Tue. So current is empty! Next one should be next Monday!
      final now = DateTime(2026, 10, 14, 8, 0); // Wednesday
      final result = findUpcomingTrips(
        stopId: StopId('stop_A'),
        timetable: timetable,
        now: now,
      );

      expect(result.current, isEmpty);
      expect(result.nextLater.isNotEmpty, isTrue);
      expect(result.nextLater.first.tripId, TripId('trip_1'));
      // Next Monday is 2026-10-19
      expect(
        result.nextLater.first.scheduledDeparture,
        DateTime(2026, 10, 19, 8, 0),
      );
    });

    test('deterministic boundary test for the 7-day horizon', () {
      // Prove that a qualifying service inside the allowed horizon (day 1..7) is found,
      // and that we do not return occurrences from day 8 or beyond.
      // We query on Wednesday 08:00 (2026-10-14).
      // Current is empty. Next 7 days are evaluated (1..7).
      // Monday (dayOffset = 5) will have Trip 1 and Trip 2.
      // Tuesday (dayOffset = 6) will have Trip 1.
      // What about NEXT Monday (dayOffset = 12)? It is > 7, so it should NOT be in nextLater.
      final now = DateTime(2026, 10, 14, 8, 0); // Wednesday

      // If we ask for a large limit, it should only return occurrences within 1..7 days.
      final result = findUpcomingTrips(
        stopId: StopId('stop_A'),
        timetable: timetable,
        now: now,
        limit: 100,
      );

      expect(result.current, isEmpty);

      // The occurrences in nextLater should only be from the next 7 days.
      // Mon (dayOffset 5) -> Trip 1 at 08:00, Trip 2 at 23:45
      // Tue (dayOffset 6) -> Trip 1 at 08:00
      expect(result.nextLater.length, 3);

      // Explicitly assert the exact 3 expected occurrences.
      // This proves that occurrences within dayOffset 1..7 are returned
      // and occurrences from dayOffset 8 or later (e.g., the following Monday) are NOT returned.

      // 1. Monday 08:00 (dayOffset = 5)
      expect(result.nextLater[0].tripId, TripId('trip_1'));
      expect(
        result.nextLater[0].scheduledDeparture,
        DateTime(2026, 10, 19, 8, 0),
      );

      // 2. Monday 23:45 (dayOffset = 5)
      expect(result.nextLater[1].tripId, TripId('trip_2'));
      expect(
        result.nextLater[1].scheduledDeparture,
        DateTime(2026, 10, 19, 23, 45),
      );

      // 3. Tuesday 08:00 (dayOffset = 6)
      expect(result.nextLater[2].tripId, TripId('trip_1'));
      expect(
        result.nextLater[2].scheduledDeparture,
        DateTime(2026, 10, 20, 8, 0),
      );
    });
  });
}
