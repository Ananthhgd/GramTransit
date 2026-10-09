import '../domain/ids.dart';
import '../domain/localized_text.dart';
import '../domain/service_days.dart';
import '../domain/service_time.dart';
import '../domain/transit_models.dart';
import 'timetable_dto.dart';
import 'timetable_format_exception.dart';

abstract final class TimetableMapper {
  static Timetable toDomain(TimetableDto dto) {
    if (dto.schemaVersion != 1) {
      throw const TimetableFormatException(
        r'$.schemaVersion',
        'Unsupported schemaVersion, expected 1',
      );
    }
    if (dto.datasetVersion.trim().isEmpty) {
      throw const TimetableFormatException(
        r'$.datasetVersion',
        'Dataset version cannot be empty',
      );
    }

    final stops = <TransitStop>[];
    final stopIds = <String>{};
    for (var i = 0; i < dto.stops.length; i++) {
      final s = dto.stops[i];
      final path = '\$.stops[$i]';
      if (s.id.trim().isEmpty) {
        throw TimetableFormatException('$path.id', 'Stop ID cannot be empty');
      }
      if (!stopIds.add(s.id)) {
        throw TimetableFormatException('$path.id', 'Duplicate Stop ID');
      }
      if (s.name.en.trim().isEmpty) {
        throw TimetableFormatException(
          '$path.name.en',
          'Stop English name cannot be empty',
        );
      }
      stops.add(
        TransitStop(
          id: StopId(s.id),
          name: LocalizedText(english: s.name.en),
        ),
      );
    }

    final routes = <TransitRoute>[];
    final routeIds = <String>{};
    for (var i = 0; i < dto.routes.length; i++) {
      final r = dto.routes[i];
      final path = '\$.routes[$i]';
      if (r.id.trim().isEmpty) {
        throw TimetableFormatException('$path.id', 'Route ID cannot be empty');
      }
      if (!routeIds.add(r.id)) {
        throw TimetableFormatException('$path.id', 'Duplicate Route ID');
      }
      if (r.shortName.en.trim().isEmpty) {
        throw TimetableFormatException(
          '$path.shortName.en',
          'Route short English name cannot be empty',
        );
      }
      if (r.longName.en.trim().isEmpty) {
        throw TimetableFormatException(
          '$path.longName.en',
          'Route long English name cannot be empty',
        );
      }
      routes.add(
        TransitRoute(
          id: RouteId(r.id),
          shortName: LocalizedText(english: r.shortName.en),
          longName: LocalizedText(english: r.longName.en),
        ),
      );
    }

    final trips = <ScheduledTrip>[];
    final tripIds = <String>{};
    for (var i = 0; i < dto.trips.length; i++) {
      final t = dto.trips[i];
      final path = '\$.trips[$i]';

      if (t.id.trim().isEmpty) {
        throw TimetableFormatException('$path.id', 'Trip ID cannot be empty');
      }
      if (!tripIds.add(t.id)) {
        throw TimetableFormatException('$path.id', 'Duplicate Trip ID');
      }
      if (!routeIds.contains(t.routeId)) {
        throw TimetableFormatException(
          '$path.routeId',
          'Route ID does not exist in routes array',
        );
      }

      if (t.serviceDays.isEmpty) {
        throw TimetableFormatException(
          '$path.serviceDays',
          'Trip must have at least one service day',
        );
      }
      final seenDays = <String>{};
      bool mon = false,
          tue = false,
          wed = false,
          thu = false,
          fri = false,
          sat = false,
          sun = false;
      for (var j = 0; j < t.serviceDays.length; j++) {
        final day = t.serviceDays[j];
        if (!seenDays.add(day)) {
          throw TimetableFormatException(
            '$path.serviceDays[$j]',
            'Duplicate service day: $day',
          );
        }
        switch (day) {
          case 'mon':
            mon = true;
            break;
          case 'tue':
            tue = true;
            break;
          case 'wed':
            wed = true;
            break;
          case 'thu':
            thu = true;
            break;
          case 'fri':
            fri = true;
            break;
          case 'sat':
            sat = true;
            break;
          case 'sun':
            sun = true;
            break;
          default:
            throw TimetableFormatException(
              '$path.serviceDays[$j]',
              'Invalid service day token: $day',
            );
        }
      }

      final serviceDays = ServiceDays(
        monday: mon,
        tuesday: tue,
        wednesday: wed,
        thursday: thu,
        friday: fri,
        saturday: sat,
        sunday: sun,
      );

      if (t.stopTimes.isEmpty) {
        throw TimetableFormatException(
          '$path.stopTimes',
          'Trip must have at least one stop time',
        );
      }

      final stopTimes = <StopTime>[];
      final seenStops = <String>{};
      for (var j = 0; j < t.stopTimes.length; j++) {
        final st = t.stopTimes[j];
        final stPath = '$path.stopTimes[$j]';

        if (!stopIds.contains(st.stopId)) {
          throw TimetableFormatException(
            '$stPath.stopId',
            'Stop ID does not exist in stops array',
          );
        }
        if (!seenStops.add(st.stopId)) {
          throw TimetableFormatException(
            '$stPath.stopId',
            'Trip cannot visit the same stop more than once',
          );
        }

        final arrival = _parseServiceTime(
          st.arrivalTime,
          '$stPath.arrivalTime',
        );
        final departure = _parseServiceTime(
          st.departureTime,
          '$stPath.departureTime',
        );

        if (departure.compareTo(arrival) < 0) {
          throw TimetableFormatException(
            stPath,
            'Departure time cannot be before arrival time',
          );
        }

        if (j > 0) {
          final previousDeparture = stopTimes.last.departureTime;
          if (arrival.compareTo(previousDeparture) < 0) {
            throw TimetableFormatException(
              stPath,
              "Arrival time cannot be before previous stop's departure time",
            );
          }
        }

        stopTimes.add(
          StopTime(
            stopId: StopId(st.stopId),
            arrivalTime: arrival,
            departureTime: departure,
          ),
        );
      }

      trips.add(
        ScheduledTrip(
          id: TripId(t.id),
          routeId: RouteId(t.routeId),
          serviceDays: serviceDays,
          stopTimes: stopTimes,
        ),
      );
    }

    final info = TimetableInfo(
      datasetVersion: dto.datasetVersion,
      isSampleData: dto.isSampleData,
    );

    return Timetable(info: info, stops: stops, routes: routes, trips: trips);
  }

  static ServiceTime _parseServiceTime(String timeStr, String path) {
    if (timeStr.length != 5 || timeStr[2] != ':') {
      throw TimetableFormatException(path, 'Time must be in HH:mm format');
    }
    final hourStr = timeStr.substring(0, 2);
    final minStr = timeStr.substring(3, 5);
    final hour = int.tryParse(hourStr);
    final min = int.tryParse(minStr);

    if (hour == null || min == null) {
      throw TimetableFormatException(path, 'Time must be in HH:mm format');
    }
    if (hour < 0 || hour > 47) {
      throw TimetableFormatException(path, 'Hour must be between 00 and 47');
    }
    if (min < 0 || min > 59) {
      throw TimetableFormatException(path, 'Minute must be between 00 and 59');
    }

    return ServiceTime(hour: hour, minute: min);
  }
}
