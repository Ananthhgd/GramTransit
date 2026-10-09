import 'ids.dart';
import 'localized_text.dart';
import 'service_days.dart';
import 'service_time.dart';

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

int _hashList(List<Object?> list) {
  return Object.hashAll(list);
}

final class TransitStop {
  final StopId id;
  final LocalizedText name;

  const TransitStop({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransitStop &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);
}

final class TransitRoute {
  final RouteId id;
  final LocalizedText shortName;
  final LocalizedText longName;

  const TransitRoute({
    required this.id,
    required this.shortName,
    required this.longName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransitRoute &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          shortName == other.shortName &&
          longName == other.longName;

  @override
  int get hashCode => Object.hash(id, shortName, longName);
}

final class StopTime {
  final StopId stopId;
  final ServiceTime arrivalTime;
  final ServiceTime departureTime;

  StopTime({
    required this.stopId,
    required this.arrivalTime,
    required this.departureTime,
  }) {
    if (departureTime.compareTo(arrivalTime) < 0) {
      throw ArgumentError('departureTime cannot be before arrivalTime');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StopTime &&
          runtimeType == other.runtimeType &&
          stopId == other.stopId &&
          arrivalTime == other.arrivalTime &&
          departureTime == other.departureTime;

  @override
  int get hashCode => Object.hash(stopId, arrivalTime, departureTime);
}

final class ScheduledTrip {
  final TripId id;
  final RouteId routeId;
  final ServiceDays serviceDays;
  final List<StopTime> stopTimes;

  ScheduledTrip({
    required this.id,
    required this.routeId,
    required this.serviceDays,
    required Iterable<StopTime> stopTimes,
  }) : stopTimes = List.unmodifiable(stopTimes) {
    if (this.stopTimes.isEmpty) {
      throw ArgumentError('ScheduledTrip must have at least one StopTime');
    }
    // Verify times are sequential
    for (var i = 0; i < this.stopTimes.length - 1; i++) {
      if (this.stopTimes[i].departureTime.compareTo(
            this.stopTimes[i + 1].arrivalTime,
          ) >
          0) {
        throw ArgumentError('Stop times must be sequentially ordered');
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledTrip &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          routeId == other.routeId &&
          serviceDays == other.serviceDays &&
          _listEquals(stopTimes, other.stopTimes);

  @override
  int get hashCode =>
      Object.hash(id, routeId, serviceDays, _hashList(stopTimes));
}

final class TimetableInfo {
  final String version;
  final DateTime validFrom;

  TimetableInfo({required this.version, required this.validFrom}) {
    if (version.trim().isEmpty) {
      throw ArgumentError(
        'TimetableInfo version cannot be empty or whitespace',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableInfo &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          validFrom == other.validFrom;

  @override
  int get hashCode => Object.hash(version, validFrom);
}

final class Timetable {
  final TimetableInfo info;
  final List<TransitStop> stops;
  final List<TransitRoute> routes;
  final List<ScheduledTrip> trips;

  Timetable({
    required this.info,
    required Iterable<TransitStop> stops,
    required Iterable<TransitRoute> routes,
    required Iterable<ScheduledTrip> trips,
  }) : stops = List.unmodifiable(stops),
       routes = List.unmodifiable(routes),
       trips = List.unmodifiable(trips);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Timetable &&
          runtimeType == other.runtimeType &&
          info == other.info &&
          _listEquals(stops, other.stops) &&
          _listEquals(routes, other.routes) &&
          _listEquals(trips, other.trips);

  @override
  int get hashCode =>
      Object.hash(info, _hashList(stops), _hashList(routes), _hashList(trips));
}
