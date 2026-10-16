part of 'upcoming_trips_logic.dart';

ScheduledJourney _toScheduledJourney(
  Timetable timetable,
  _BoardingCandidate candidate,
  StopId boardingStopId,
  StopId alightingStopId,
) {
  final trip = candidate.trip;
  final route = timetable.routes.firstWhere((r) => r.id == trip.routeId);
  final boardingStop = timetable.stops.firstWhere(
    (s) => s.id == boardingStopId,
  );
  final alightingStop = timetable.stops.firstWhere(
    (s) => s.id == alightingStopId,
  );
  final finalStop = timetable.stops.firstWhere(
    (s) => s.id == trip.stopTimes.last.stopId,
  );

  final alightingStopTime = candidate.alightingStopTime!;
  final scheduledArrival = alightingStopTime.arrivalTime.toDateTime(
    candidate.serviceDate,
  );

  return ScheduledJourney(
    tripId: trip.id,
    routeId: route.id,
    routeShortName: route.shortName,
    routeLongName: route.longName,
    tripHeadsign: finalStop.name,
    boardingStopId: boardingStop.id,
    boardingStopName: boardingStop.name,
    alightingStopId: alightingStop.id,
    alightingStopName: alightingStop.name,
    serviceDate: candidate.serviceDate,
    scheduledDeparture: candidate.scheduledDeparture,
    scheduledArrival: scheduledArrival,
  );
}

/// Returns direct upcoming scheduled journeys from [boardingStopId] to [alightingStopId].
///
/// Throws [ArgumentError] if either stop is not found in [timetable], or if
/// [boardingStopId] and [alightingStopId] are the same stop.
///
/// Evaluates yesterday and today service dates for immediate [current] departures.
/// When [current] is empty, populates [nextLater] over the next 7 service dates.
UpcomingJourneys findUpcomingJourneys({
  required StopId boardingStopId,
  required StopId alightingStopId,
  required Timetable timetable,
  required DateTime now,
  int limit = 10,
}) {
  timetable.stops.firstWhere(
    (s) => s.id == boardingStopId,
    orElse: () => throw ArgumentError('Stop not found in timetable'),
  );
  timetable.stops.firstWhere(
    (s) => s.id == alightingStopId,
    orElse: () => throw ArgumentError('Stop not found in timetable'),
  );

  if (boardingStopId == alightingStopId) {
    throw ArgumentError(
      'Boarding stop and alighting stop must not be the same',
    );
  }

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
    boardingStopId: boardingStopId,
    alightingStopId: alightingStopId,
    queryMinute: queryMinute,
    startDayOffset: -1,
    endDayOffset: 0,
  );

  final List<ScheduledJourney> current = currentCandidates
      .map(
        (c) =>
            _toScheduledJourney(timetable, c, boardingStopId, alightingStopId),
      )
      .toList();

  final List<ScheduledJourney> nextLater = [];

  // If no eligible current upcoming scheduled journeys exist, derive nextLater
  if (current.isEmpty) {
    final nextLaterCandidates = _evaluateBoardingCandidates(
      timetable: timetable,
      boardingStopId: boardingStopId,
      alightingStopId: alightingStopId,
      queryMinute: queryMinute,
      startDayOffset: 1,
      endDayOffset: 7,
    );

    nextLater.addAll(
      nextLaterCandidates.map(
        (c) =>
            _toScheduledJourney(timetable, c, boardingStopId, alightingStopId),
      ),
    );
  }

  return UpcomingJourneys(
    boardingStopId: boardingStopId,
    alightingStopId: alightingStopId,
    queryTime: now,
    current: current.take(limit).toList(),
    nextLater: nextLater.take(limit).toList(),
  );
}
