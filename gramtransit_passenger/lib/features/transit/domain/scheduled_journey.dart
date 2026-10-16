import 'ids.dart';
import 'localized_text.dart';

/// Immutable domain representation of a single scheduled direct journey
/// from a [boardingStopId] to a downstream [alightingStopId] for one service occurrence.
final class ScheduledJourney {
  final TripId tripId;
  final RouteId routeId;
  final LocalizedText routeShortName;
  final LocalizedText routeLongName;
  final LocalizedText tripHeadsign;
  final StopId boardingStopId;
  final LocalizedText boardingStopName;
  final StopId alightingStopId;
  final LocalizedText alightingStopName;
  final DateTime serviceDate;
  final DateTime scheduledDeparture;
  final DateTime scheduledArrival;

  ScheduledJourney({
    required this.tripId,
    required this.routeId,
    required this.routeShortName,
    required this.routeLongName,
    required this.tripHeadsign,
    required this.boardingStopId,
    required this.boardingStopName,
    required this.alightingStopId,
    required this.alightingStopName,
    required this.serviceDate,
    required this.scheduledDeparture,
    required this.scheduledArrival,
  }) {
    if (boardingStopId == alightingStopId) {
      throw ArgumentError(
        'boardingStopId and alightingStopId must not be equal',
      );
    }
    if (scheduledArrival.isBefore(scheduledDeparture)) {
      throw ArgumentError(
        'scheduledArrival cannot be before scheduledDeparture',
      );
    }
  }

  Duration get scheduledDuration =>
      scheduledArrival.difference(scheduledDeparture);

  bool get arrivesOnLaterCalendarDay {
    final depCalendarDate = DateTime(
      scheduledDeparture.year,
      scheduledDeparture.month,
      scheduledDeparture.day,
    );
    final arrCalendarDate = DateTime(
      scheduledArrival.year,
      scheduledArrival.month,
      scheduledArrival.day,
    );
    return arrCalendarDate.isAfter(depCalendarDate);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledJourney &&
          runtimeType == other.runtimeType &&
          tripId == other.tripId &&
          routeId == other.routeId &&
          routeShortName == other.routeShortName &&
          routeLongName == other.routeLongName &&
          tripHeadsign == other.tripHeadsign &&
          boardingStopId == other.boardingStopId &&
          boardingStopName == other.boardingStopName &&
          alightingStopId == other.alightingStopId &&
          alightingStopName == other.alightingStopName &&
          serviceDate == other.serviceDate &&
          scheduledDeparture == other.scheduledDeparture &&
          scheduledArrival == other.scheduledArrival;

  @override
  int get hashCode => Object.hash(
    tripId,
    routeId,
    routeShortName,
    routeLongName,
    tripHeadsign,
    boardingStopId,
    boardingStopName,
    alightingStopId,
    alightingStopName,
    serviceDate,
    scheduledDeparture,
    scheduledArrival,
  );
}

/// Immutable domain result representing direct scheduled journeys found for a query.
final class UpcomingJourneys {
  final StopId boardingStopId;
  final StopId alightingStopId;
  final DateTime queryTime;
  final List<ScheduledJourney> current;
  final List<ScheduledJourney> nextLater;

  UpcomingJourneys({
    required this.boardingStopId,
    required this.alightingStopId,
    required this.queryTime,
    required Iterable<ScheduledJourney> current,
    required Iterable<ScheduledJourney> nextLater,
  }) : current = List.unmodifiable(current),
       nextLater = List.unmodifiable(nextLater);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UpcomingJourneys ||
        runtimeType != other.runtimeType ||
        boardingStopId != other.boardingStopId ||
        alightingStopId != other.alightingStopId ||
        queryTime != other.queryTime ||
        current.length != other.current.length ||
        nextLater.length != other.nextLater.length) {
      return false;
    }
    for (int i = 0; i < current.length; i++) {
      if (current[i] != other.current[i]) return false;
    }
    for (int i = 0; i < nextLater.length; i++) {
      if (nextLater[i] != other.nextLater[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    boardingStopId,
    alightingStopId,
    queryTime,
    Object.hashAll(current),
    Object.hashAll(nextLater),
  );
}
