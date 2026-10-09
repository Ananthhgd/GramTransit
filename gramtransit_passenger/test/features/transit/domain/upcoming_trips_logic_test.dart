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
        info: TimetableInfo(version: '1', validFrom: DateTime(2026, 1, 1)),
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
        ],
        routes: [
          TransitRoute(
            id: RouteId('route_1'),
            shortName: LocalizedText(english: 'R1'),
            longName: LocalizedText(english: 'Route 1'),
          ),
        ],
        trips: [
          // Trip 1: Morning trip, departs A at 08:00, arrives C at 08:30
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
          // Trip 2: Late night trip, departs A at 23:45, arrives C at 24:15 (next day 00:15)
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

    test('a trip currently in progress remains relevant because scheduled end >= now', () {
      // Query at Stop B. The bus departed A at 08:00, arrives B at 08:15.
      // Current time is 08:10. The trip is in progress.
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

    test(
      'trip ending exactly at now remains relevant for the terminus stop',
      () {
        // Query at Stop C. Trip 1 arrives at 08:30.
        final now = DateTime(2026, 10, 12, 8, 30);
        final result = findUpcomingTrips(
          stopId: StopId('stop_C'),
          timetable: timetable,
          now: now,
        );

        expect(result.current.first.tripId, TripId('trip_1'));
        expect(result.nextLater, isEmpty);
      },
    );

    test('trip ending before now is not treated as current/relevant', () {
      // Query at Stop B at 08:40. Trip 1 ended at 08:30. It should NOT be relevant.
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
      // Query at Stop B on TUESDAY at 00:05 (2026-10-13 00:05).
      // Trip 2 operates on MONDAY, but arrives at Stop C at 24:15 (Tuesday 00:15).
      // Let's query Stop C instead. Arrives at 24:15 (Tue 00:15).
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
