import 'ids.dart';
import 'localized_text.dart';

final class TripOccurrence {
  final TripId tripId;
  final RouteId routeId;
  final LocalizedText routeShortName;
  final LocalizedText routeLongName;
  final LocalizedText destinationName;

  /// The absolute actual departure time for this specific stop occurrence.
  final DateTime scheduledDeparture;

  /// The absolute time the trip reaches its final destination.
  final DateTime tripEnd;

  const TripOccurrence({
    required this.tripId,
    required this.routeId,
    required this.routeShortName,
    required this.routeLongName,
    required this.destinationName,
    required this.scheduledDeparture,
    required this.tripEnd,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripOccurrence &&
          runtimeType == other.runtimeType &&
          tripId == other.tripId &&
          routeId == other.routeId &&
          routeShortName == other.routeShortName &&
          routeLongName == other.routeLongName &&
          destinationName == other.destinationName &&
          scheduledDeparture == other.scheduledDeparture &&
          tripEnd == other.tripEnd;

  @override
  int get hashCode => Object.hash(
    tripId,
    routeId,
    routeShortName,
    routeLongName,
    destinationName,
    scheduledDeparture,
    tripEnd,
  );
}

final class UpcomingTrips {
  final StopId stopId;
  final DateTime queryTime;
  final List<TripOccurrence> current;
  final List<TripOccurrence> nextLater;

  UpcomingTrips({
    required this.stopId,
    required this.queryTime,
    required Iterable<TripOccurrence> current,
    required Iterable<TripOccurrence> nextLater,
  }) : current = List.unmodifiable(current),
       nextLater = List.unmodifiable(nextLater);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UpcomingTrips ||
        runtimeType != other.runtimeType ||
        stopId != other.stopId ||
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
    stopId,
    queryTime,
    Object.hashAll(current),
    Object.hashAll(nextLater),
  );
}
