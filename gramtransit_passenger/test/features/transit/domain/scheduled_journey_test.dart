import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/scheduled_journey.dart';

void main() {
  group('ScheduledJourney', () {
    test('derived positive duration is computed correctly', () {
      final journey = ScheduledJourney(
        tripId: TripId('trip_1'),
        routeId: RouteId('route_1'),
        routeShortName: LocalizedText(english: 'R1'),
        routeLongName: LocalizedText(english: 'Route 1'),
        tripHeadsign: LocalizedText(english: 'Terminus'),
        boardingStopId: StopId('stop_A'),
        boardingStopName: LocalizedText(english: 'Stop A'),
        alightingStopId: StopId('stop_B'),
        alightingStopName: LocalizedText(english: 'Stop B'),
        serviceDate: DateTime(2026, 10, 12),
        scheduledDeparture: DateTime(2026, 10, 12, 8, 0),
        scheduledArrival: DateTime(2026, 10, 12, 8, 30),
      );

      expect(journey.scheduledDuration, const Duration(minutes: 30));
    });

    test('zero duration is valid and accepted', () {
      final journey = ScheduledJourney(
        tripId: TripId('trip_zero'),
        routeId: RouteId('route_1'),
        routeShortName: LocalizedText(english: 'R1'),
        routeLongName: LocalizedText(english: 'Route 1'),
        tripHeadsign: LocalizedText(english: 'Terminus'),
        boardingStopId: StopId('stop_A'),
        boardingStopName: LocalizedText(english: 'Stop A'),
        alightingStopId: StopId('stop_B'),
        alightingStopName: LocalizedText(english: 'Stop B'),
        serviceDate: DateTime(2026, 10, 12),
        scheduledDeparture: DateTime(2026, 10, 12, 8, 0),
        scheduledArrival: DateTime(2026, 10, 12, 8, 0),
      );

      expect(journey.scheduledDuration, Duration.zero);
    });

    test('arrival before departure is rejected with ArgumentError', () {
      expect(
        () => ScheduledJourney(
          tripId: TripId('trip_inv'),
          routeId: RouteId('route_1'),
          routeShortName: LocalizedText(english: 'R1'),
          routeLongName: LocalizedText(english: 'Route 1'),
          tripHeadsign: LocalizedText(english: 'Terminus'),
          boardingStopId: StopId('stop_A'),
          boardingStopName: LocalizedText(english: 'Stop A'),
          alightingStopId: StopId('stop_B'),
          alightingStopName: LocalizedText(english: 'Stop B'),
          serviceDate: DateTime(2026, 10, 12),
          scheduledDeparture: DateTime(2026, 10, 12, 8, 30),
          scheduledArrival: DateTime(2026, 10, 12, 8, 0),
        ),
        throwsArgumentError,
      );
    });

    test('same boarding and alighting stop is rejected with ArgumentError', () {
      expect(
        () => ScheduledJourney(
          tripId: TripId('trip_same'),
          routeId: RouteId('route_1'),
          routeShortName: LocalizedText(english: 'R1'),
          routeLongName: LocalizedText(english: 'Route 1'),
          tripHeadsign: LocalizedText(english: 'Terminus'),
          boardingStopId: StopId('stop_A'),
          boardingStopName: LocalizedText(english: 'Stop A'),
          alightingStopId: StopId('stop_A'),
          alightingStopName: LocalizedText(english: 'Stop A'),
          serviceDate: DateTime(2026, 10, 12),
          scheduledDeparture: DateTime(2026, 10, 12, 8, 0),
          scheduledArrival: DateTime(2026, 10, 12, 8, 30),
        ),
        throwsArgumentError,
      );
    });

    test('arrivesOnLaterCalendarDay is false for same calendar day', () {
      final journey = ScheduledJourney(
        tripId: TripId('trip_1'),
        routeId: RouteId('route_1'),
        routeShortName: LocalizedText(english: 'R1'),
        routeLongName: LocalizedText(english: 'Route 1'),
        tripHeadsign: LocalizedText(english: 'Terminus'),
        boardingStopId: StopId('stop_A'),
        boardingStopName: LocalizedText(english: 'Stop A'),
        alightingStopId: StopId('stop_B'),
        alightingStopName: LocalizedText(english: 'Stop B'),
        serviceDate: DateTime(2026, 10, 12),
        scheduledDeparture: DateTime(2026, 10, 12, 8, 0),
        scheduledArrival: DateTime(2026, 10, 12, 8, 30),
      );

      expect(journey.arrivesOnLaterCalendarDay, isFalse);
    });

    test('arrivesOnLaterCalendarDay is true for overnight journey', () {
      final journey = ScheduledJourney(
        tripId: TripId('trip_overnight'),
        routeId: RouteId('route_1'),
        routeShortName: LocalizedText(english: 'R1'),
        routeLongName: LocalizedText(english: 'Route 1'),
        tripHeadsign: LocalizedText(english: 'Terminus'),
        boardingStopId: StopId('stop_A'),
        boardingStopName: LocalizedText(english: 'Stop A'),
        alightingStopId: StopId('stop_B'),
        alightingStopName: LocalizedText(english: 'Stop B'),
        serviceDate: DateTime(2026, 10, 12),
        scheduledDeparture: DateTime(2026, 10, 12, 23, 45),
        scheduledArrival: DateTime(2026, 10, 13, 0, 15),
      );

      expect(journey.arrivesOnLaterCalendarDay, isTrue);
    });

    test('value equality and hashCode', () {
      final j1 = ScheduledJourney(
        tripId: TripId('trip_1'),
        routeId: RouteId('route_1'),
        routeShortName: LocalizedText(english: 'R1'),
        routeLongName: LocalizedText(english: 'Route 1'),
        tripHeadsign: LocalizedText(english: 'Terminus'),
        boardingStopId: StopId('stop_A'),
        boardingStopName: LocalizedText(english: 'Stop A'),
        alightingStopId: StopId('stop_B'),
        alightingStopName: LocalizedText(english: 'Stop B'),
        serviceDate: DateTime(2026, 10, 12),
        scheduledDeparture: DateTime(2026, 10, 12, 8, 0),
        scheduledArrival: DateTime(2026, 10, 12, 8, 30),
      );
      final j2 = ScheduledJourney(
        tripId: TripId('trip_1'),
        routeId: RouteId('route_1'),
        routeShortName: LocalizedText(english: 'R1'),
        routeLongName: LocalizedText(english: 'Route 1'),
        tripHeadsign: LocalizedText(english: 'Terminus'),
        boardingStopId: StopId('stop_A'),
        boardingStopName: LocalizedText(english: 'Stop A'),
        alightingStopId: StopId('stop_B'),
        alightingStopName: LocalizedText(english: 'Stop B'),
        serviceDate: DateTime(2026, 10, 12),
        scheduledDeparture: DateTime(2026, 10, 12, 8, 0),
        scheduledArrival: DateTime(2026, 10, 12, 8, 30),
      );

      expect(j1, equals(j2));
      expect(j1.hashCode, equals(j2.hashCode));
    });
  });

  group('UpcomingJourneys', () {
    test('value equality and unmodifiable lists', () {
      final now = DateTime(2026, 10, 12, 8, 0);
      final u1 = UpcomingJourneys(
        boardingStopId: StopId('stop_A'),
        alightingStopId: StopId('stop_B'),
        queryTime: now,
        current: [],
        nextLater: [],
      );
      final u2 = UpcomingJourneys(
        boardingStopId: StopId('stop_A'),
        alightingStopId: StopId('stop_B'),
        queryTime: now,
        current: [],
        nextLater: [],
      );

      final dummyJourney = ScheduledJourney(
        tripId: TripId('trip_1'),
        routeId: RouteId('route_1'),
        routeShortName: LocalizedText(english: 'R1'),
        routeLongName: LocalizedText(english: 'Route 1'),
        tripHeadsign: LocalizedText(english: 'Terminus'),
        boardingStopId: StopId('stop_A'),
        boardingStopName: LocalizedText(english: 'Stop A'),
        alightingStopId: StopId('stop_B'),
        alightingStopName: LocalizedText(english: 'Stop B'),
        serviceDate: DateTime(2026, 10, 12),
        scheduledDeparture: DateTime(2026, 10, 12, 8, 0),
        scheduledArrival: DateTime(2026, 10, 12, 8, 30),
      );

      expect(u1, equals(u2));
      expect(u1.hashCode, equals(u2.hashCode));
      expect(() => u1.current.add(dummyJourney), throwsUnsupportedError);
      expect(() => u1.nextLater.add(dummyJourney), throwsUnsupportedError);
    });
  });
}
