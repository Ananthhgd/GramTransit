import 'ids.dart';
import 'transit_models.dart';
import 'trip_occurrence.dart';

/// Private candidate representation of a boardable trip occurrence at a queried stop.
final class _BoardingCandidate {
  final ScheduledTrip trip;
  final DateTime serviceDate;
  final int boardingStopIndex;
  final StopTime boardingStopTime;
  final DateTime scheduledDeparture;

  const _BoardingCandidate({
    required this.trip,
    required this.serviceDate,
    required this.boardingStopIndex,
    required this.boardingStopTime,
    required this.scheduledDeparture,
  });
}

/// Evaluates boardable trip candidates across a range of day offsets relative to [queryMinute].
///
/// Filters for service-day operation, non-terminal stop boarding, and unpassed departures
/// (inclusive of [queryMinute]). Candidates are sorted deterministically by [scheduledDeparture].
List<_BoardingCandidate> _evaluateBoardingCandidates({
  required Timetable timetable,
  required StopId boardingStopId,
  required DateTime queryMinute,
  required int startDayOffset,
  required int endDayOffset,
}) {
  final List<_BoardingCandidate> candidates = [];
  final DateTime baseDate = DateTime(
    queryMinute.year,
    queryMinute.month,
    queryMinute.day,
  );

  for (int dayOffset = startDayOffset; dayOffset <= endDayOffset; dayOffset++) {
    final candidateDate = baseDate.add(Duration(days: dayOffset));

    for (final trip in timetable.trips) {
      if (!trip.serviceDays.operatesOn(candidateDate)) continue;

      final stopIndex = trip.stopTimes.indexWhere(
        (st) => st.stopId == boardingStopId,
      );
      if (stopIndex == -1) continue;

      // Exclude terminal / final stop as passengers cannot board.
      if (stopIndex == trip.stopTimes.length - 1) continue;

      final stopTime = trip.stopTimes[stopIndex];
      final departureTimeAbsolute = stopTime.departureTime.toDateTime(
        candidateDate,
      );

      if (departureTimeAbsolute.isBefore(queryMinute)) continue;

      candidates.add(
        _BoardingCandidate(
          trip: trip,
          serviceDate: candidateDate,
          boardingStopIndex: stopIndex,
          boardingStopTime: stopTime,
          scheduledDeparture: departureTimeAbsolute,
        ),
      );
    }
  }

  candidates.sort(
    (a, b) => a.scheduledDeparture.compareTo(b.scheduledDeparture),
  );

  return candidates;
}

TripOccurrence _toTripOccurrence(
  Timetable timetable,
  _BoardingCandidate candidate,
) {
  final trip = candidate.trip;
  final lastStopTime = trip.stopTimes.last;
  final tripEndAbsolute = lastStopTime.arrivalTime.toDateTime(
    candidate.serviceDate,
  );

  final route = timetable.routes.firstWhere((r) => r.id == trip.routeId);
  final destStop = timetable.stops.firstWhere(
    (s) => s.id == lastStopTime.stopId,
  );

  return TripOccurrence(
    tripId: trip.id,
    routeId: route.id,
    routeShortName: route.shortName,
    routeLongName: route.longName,
    destinationName: destStop.name,
    scheduledDeparture: candidate.scheduledDeparture,
    tripEnd: tripEndAbsolute,
  );
}

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

  // Evaluate candidate service dates for yesterday and today
  final currentCandidates = _evaluateBoardingCandidates(
    timetable: timetable,
    boardingStopId: stopId,
    queryMinute: queryMinute,
    startDayOffset: -1,
    endDayOffset: 0,
  );

  final List<TripOccurrence> current = currentCandidates
      .map((c) => _toTripOccurrence(timetable, c))
      .toList();

  final List<TripOccurrence> nextLater = [];

  // If no appropriate immediate/current upcoming scheduled service exists, derive nextLater
  if (current.isEmpty) {
    final nextLaterCandidates = _evaluateBoardingCandidates(
      timetable: timetable,
      boardingStopId: stopId,
      queryMinute: queryMinute,
      startDayOffset: 1,
      endDayOffset: 7,
    );

    nextLater.addAll(
      nextLaterCandidates.map((c) => _toTripOccurrence(timetable, c)),
    );
  }

  return UpcomingTrips(
    stopId: stopId,
    queryTime: now,
    current: current.take(limit).toList(),
    nextLater: nextLater.take(limit).toList(),
  );
}
