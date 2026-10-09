import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';

import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';

void main() {
  group('Transit Models', () {
    test('valid ScheduledTrip', () {
      final trip = ScheduledTrip(
        id: TripId('t1'),
        routeId: RouteId('r1'),
        serviceDays: const ServiceDays(monday: true),
        stopTimes: [
          StopTime(
            stopId: StopId('s1'),
            arrivalTime: ServiceTime(hour: 8, minute: 0),
            departureTime: ServiceTime(hour: 8, minute: 5),
          ),
          StopTime(
            stopId: StopId('s2'),
            arrivalTime: ServiceTime(hour: 8, minute: 15),
            departureTime: ServiceTime(hour: 8, minute: 20),
          ),
        ],
      );

      expect(trip.id, TripId('t1'));
    });

    test('invalid structural states', () {
      expect(
        () => ScheduledTrip(
          id: TripId('t1'),
          routeId: RouteId('r1'),
          serviceDays: const ServiceDays(),
          stopTimes: [],
        ),
        throwsArgumentError,
      );

      expect(
        () => ScheduledTrip(
          id: TripId('t1'),
          routeId: RouteId('r1'),
          serviceDays: const ServiceDays(),
          stopTimes: [
            StopTime(
              stopId: StopId('s1'),
              arrivalTime: ServiceTime(hour: 8, minute: 0),
              departureTime: ServiceTime(hour: 8, minute: 20),
            ),
            StopTime(
              stopId: StopId('s2'),
              arrivalTime: ServiceTime(hour: 8, minute: 10),
              departureTime: ServiceTime(hour: 8, minute: 20),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('StopTime departure/arrival validation', () {
      expect(
        () => StopTime(
          stopId: StopId('s1'),
          arrivalTime: ServiceTime(hour: 8, minute: 0),
          departureTime: ServiceTime(hour: 8, minute: 0),
        ),
        returnsNormally,
      );

      expect(
        () => StopTime(
          stopId: StopId('s1'),
          arrivalTime: ServiceTime(hour: 8, minute: 0),
          departureTime: ServiceTime(hour: 8, minute: 5),
        ),
        returnsNormally,
      );

      expect(
        () => StopTime(
          stopId: StopId('s1'),
          arrivalTime: ServiceTime(hour: 8, minute: 5),
          departureTime: ServiceTime(hour: 8, minute: 0),
        ),
        throwsArgumentError,
      );
    });

    test('TimetableInfo version validation', () {
      expect(
        () => TimetableInfo(version: '1', validFrom: DateTime(2026)),
        returnsNormally,
      );
      expect(
        () => TimetableInfo(version: '', validFrom: DateTime(2026)),
        throwsArgumentError,
      );
      expect(
        () => TimetableInfo(version: '   ', validFrom: DateTime(2026)),
        throwsArgumentError,
      );
    });

    test('List mutability protection', () {
      final stopTimesList = <StopTime>[
        StopTime(
          stopId: StopId('s1'),
          arrivalTime: ServiceTime(hour: 8, minute: 0),
          departureTime: ServiceTime(hour: 8, minute: 0),
        ),
      ];

      final trip = ScheduledTrip(
        id: TripId('t1'),
        routeId: RouteId('r1'),
        serviceDays: const ServiceDays(monday: true),
        stopTimes: stopTimesList,
      );

      stopTimesList.clear();
      expect(trip.stopTimes, isNotEmpty);

      expect(() => trip.stopTimes.clear(), throwsUnsupportedError);
      expect(
        () => trip.stopTimes.add(
          StopTime(
            stopId: StopId('s2'),
            arrivalTime: ServiceTime(hour: 8, minute: 0),
            departureTime: ServiceTime(hour: 8, minute: 0),
          ),
        ),
        throwsUnsupportedError,
      );

      final timetable = Timetable(
        info: TimetableInfo(version: '1', validFrom: DateTime.now()),
        stops: [],
        routes: [],
        trips: [trip],
      );

      expect(() => timetable.trips.clear(), throwsUnsupportedError);
      expect(() => timetable.routes.clear(), throwsUnsupportedError);
      expect(() => timetable.stops.clear(), throwsUnsupportedError);
    });
  });
}
