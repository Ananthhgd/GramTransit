import 'ids.dart';
import 'transit_models.dart';
import 'trip_occurrence.dart';

/// Returns boardable scheduled upcoming trips from the queried stop.
///
/// Only trips that serve [stopId] where [stopId] is not the trip's final stop
/// (terminal stops excluded) are included. Departures in the query minute are
/// included.
///
/// Evaluates yesterday and today service dates for immediate [current] departures.
/// When [current] is empty, populates [nextLater] over the next 7 service dates.
UpcomingTrips findUpcomingTrips({
  required StopId stopId,
  required Timetable timetable,
  required DateTime now,
  int limit = 10,
}) {
  timetable.stops.firstWhere(
    (s) => s.id == stopId,
    orElse: () => throw ArgumentError('Stop not found in timetable'),
  );

  final DateTime queryMinute = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
  );

  final List<TripOccurrence> current = [];
  final DateTime baseDate = DateTime(
    queryMinute.year,
    queryMinute.month,
    queryMinute.day,
  );

  // Evaluate candidate service dates for yesterday and today
  for (int dayOffset = -1; dayOffset <= 0; dayOffset++) {
    final candidateDate = baseDate.add(Duration(days: dayOffset));

    for (final trip in timetable.trips) {
      if (!trip.serviceDays.operatesOn(candidateDate)) continue;

      final stopIndex = trip.stopTimes.indexWhere((st) => st.stopId == stopId);
      if (stopIndex == -1) continue;

      // Exclude terminal / final stop as passengers cannot board.
      if (stopIndex == trip.stopTimes.length - 1) continue;

      final stopTime = trip.stopTimes[stopIndex];
      final departureTimeAbsolute = stopTime.departureTime.toDateTime(
        candidateDate,
      );

      if (departureTimeAbsolute.isBefore(queryMinute)) continue;

      final lastStopTime = trip.stopTimes.last;
      final tripEndAbsolute = lastStopTime.arrivalTime.toDateTime(
        candidateDate,
      );

      final route = timetable.routes.firstWhere((r) => r.id == trip.routeId);
      final destStop = timetable.stops.firstWhere(
        (s) => s.id == lastStopTime.stopId,
      );

      current.add(
        TripOccurrence(
          tripId: trip.id,
          routeId: route.id,
          routeShortName: route.shortName,
          routeLongName: route.longName,
          destinationName: destStop.name,
          scheduledDeparture: departureTimeAbsolute,
          tripEnd: tripEndAbsolute,
        ),
      );
    }
  }

  current.sort((a, b) => a.scheduledDeparture.compareTo(b.scheduledDeparture));

  final List<TripOccurrence> nextLater = [];

  // If no appropriate immediate/current upcoming scheduled service exists, derive nextLater
  if (current.isEmpty) {
    for (int dayOffset = 1; dayOffset <= 7; dayOffset++) {
      final candidateDate = baseDate.add(Duration(days: dayOffset));

      for (final trip in timetable.trips) {
        if (!trip.serviceDays.operatesOn(candidateDate)) continue;

        final stopIndex = trip.stopTimes.indexWhere(
          (st) => st.stopId == stopId,
        );
        if (stopIndex == -1) continue;

        // Exclude terminal / final stop as passengers cannot board.
        if (stopIndex == trip.stopTimes.length - 1) continue;

        final stopTime = trip.stopTimes[stopIndex];
        final departureTimeAbsolute = stopTime.departureTime.toDateTime(
          candidateDate,
        );

        if (departureTimeAbsolute.isBefore(queryMinute)) continue;

        final lastStopTime = trip.stopTimes.last;
        final tripEndAbsolute = lastStopTime.arrivalTime.toDateTime(
          candidateDate,
        );

        final route = timetable.routes.firstWhere((r) => r.id == trip.routeId);
        final destStop = timetable.stops.firstWhere(
          (s) => s.id == lastStopTime.stopId,
        );

        nextLater.add(
          TripOccurrence(
            tripId: trip.id,
            routeId: route.id,
            routeShortName: route.shortName,
            routeLongName: route.longName,
            destinationName: destStop.name,
            scheduledDeparture: departureTimeAbsolute,
            tripEnd: tripEndAbsolute,
          ),
        );
      }
    }
    nextLater.sort(
      (a, b) => a.scheduledDeparture.compareTo(b.scheduledDeparture),
    );
  }

  return UpcomingTrips(
    stopId: stopId,
    queryTime: now,
    current: current.take(limit).toList(),
    nextLater: nextLater.take(limit).toList(),
  );
}
