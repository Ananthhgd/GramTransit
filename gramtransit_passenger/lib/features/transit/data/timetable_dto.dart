import 'timetable_format_exception.dart';

String _expectString(Object? value, String path) {
  if (value is String) return value;
  throw TimetableFormatException(
    path,
    'Expected String but got ${value.runtimeType}',
  );
}

int _expectInt(Object? value, String path) {
  if (value is int) return value;
  throw TimetableFormatException(
    path,
    'Expected int but got ${value.runtimeType}',
  );
}

bool _expectBool(Object? value, String path) {
  if (value is bool) return value;
  throw TimetableFormatException(
    path,
    'Expected bool but got ${value.runtimeType}',
  );
}

Map<String, dynamic> _expectMap(Object? value, String path) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    try {
      return Map<String, dynamic>.from(value);
    } catch (_) {
      throw TimetableFormatException(path, 'Expected Map<String, dynamic>');
    }
  }
  throw TimetableFormatException(
    path,
    'Expected Map but got ${value.runtimeType}',
  );
}

List<dynamic> _expectList(Object? value, String path) {
  if (value is List) return value;
  throw TimetableFormatException(
    path,
    'Expected List but got ${value.runtimeType}',
  );
}

Object? _expectNotNull(Object? value, String path) {
  if (value != null) return value;
  throw TimetableFormatException(path, 'Missing or null required value');
}

final class LocalizedTextDto {
  final String en;

  const LocalizedTextDto({required this.en});

  factory LocalizedTextDto.fromJson(Object? json, String path) {
    final map = _expectMap(json, path);
    return LocalizedTextDto(
      en: _expectString(_expectNotNull(map['en'], '$path.en'), '$path.en'),
    );
  }
}

final class StopDto {
  final String id;
  final LocalizedTextDto name;

  const StopDto({required this.id, required this.name});

  factory StopDto.fromJson(Object? json, String path) {
    final map = _expectMap(json, path);
    return StopDto(
      id: _expectString(_expectNotNull(map['id'], '$path.id'), '$path.id'),
      name: LocalizedTextDto.fromJson(map['name'], '$path.name'),
    );
  }
}

final class RouteDto {
  final String id;
  final LocalizedTextDto shortName;
  final LocalizedTextDto longName;

  const RouteDto({
    required this.id,
    required this.shortName,
    required this.longName,
  });

  factory RouteDto.fromJson(Object? json, String path) {
    final map = _expectMap(json, path);
    return RouteDto(
      id: _expectString(_expectNotNull(map['id'], '$path.id'), '$path.id'),
      shortName: LocalizedTextDto.fromJson(map['shortName'], '$path.shortName'),
      longName: LocalizedTextDto.fromJson(map['longName'], '$path.longName'),
    );
  }
}

final class StopTimeDto {
  final String stopId;
  final String arrivalTime;
  final String departureTime;

  const StopTimeDto({
    required this.stopId,
    required this.arrivalTime,
    required this.departureTime,
  });

  factory StopTimeDto.fromJson(Object? json, String path) {
    final map = _expectMap(json, path);
    return StopTimeDto(
      stopId: _expectString(
        _expectNotNull(map['stopId'], '$path.stopId'),
        '$path.stopId',
      ),
      arrivalTime: _expectString(
        _expectNotNull(map['arrivalTime'], '$path.arrivalTime'),
        '$path.arrivalTime',
      ),
      departureTime: _expectString(
        _expectNotNull(map['departureTime'], '$path.departureTime'),
        '$path.departureTime',
      ),
    );
  }
}

final class TripDto {
  final String id;
  final String routeId;
  final List<String> serviceDays;
  final List<StopTimeDto> stopTimes;

  const TripDto({
    required this.id,
    required this.routeId,
    required this.serviceDays,
    required this.stopTimes,
  });

  factory TripDto.fromJson(Object? json, String path) {
    final map = _expectMap(json, path);

    final serviceDaysRaw = _expectList(
      _expectNotNull(map['serviceDays'], '$path.serviceDays'),
      '$path.serviceDays',
    );
    final serviceDays = <String>[];
    for (var i = 0; i < serviceDaysRaw.length; i++) {
      serviceDays.add(
        _expectString(serviceDaysRaw[i], '$path.serviceDays[$i]'),
      );
    }

    final stopTimesRaw = _expectList(
      _expectNotNull(map['stopTimes'], '$path.stopTimes'),
      '$path.stopTimes',
    );
    final stopTimes = <StopTimeDto>[];
    for (var i = 0; i < stopTimesRaw.length; i++) {
      stopTimes.add(
        StopTimeDto.fromJson(stopTimesRaw[i], '$path.stopTimes[$i]'),
      );
    }

    return TripDto(
      id: _expectString(_expectNotNull(map['id'], '$path.id'), '$path.id'),
      routeId: _expectString(
        _expectNotNull(map['routeId'], '$path.routeId'),
        '$path.routeId',
      ),
      serviceDays: serviceDays,
      stopTimes: stopTimes,
    );
  }
}

final class TimetableDto {
  final int schemaVersion;
  final String datasetVersion;
  final bool isSampleData;
  final List<StopDto> stops;
  final List<RouteDto> routes;
  final List<TripDto> trips;

  const TimetableDto({
    required this.schemaVersion,
    required this.datasetVersion,
    required this.isSampleData,
    required this.stops,
    required this.routes,
    required this.trips,
  });

  factory TimetableDto.fromJson(Object? json, [String path = r'$']) {
    final map = _expectMap(json, path);

    final stopsRaw = _expectList(
      _expectNotNull(map['stops'], '$path.stops'),
      '$path.stops',
    );
    final stops = <StopDto>[];
    for (var i = 0; i < stopsRaw.length; i++) {
      stops.add(StopDto.fromJson(stopsRaw[i], '$path.stops[$i]'));
    }

    final routesRaw = _expectList(
      _expectNotNull(map['routes'], '$path.routes'),
      '$path.routes',
    );
    final routes = <RouteDto>[];
    for (var i = 0; i < routesRaw.length; i++) {
      routes.add(RouteDto.fromJson(routesRaw[i], '$path.routes[$i]'));
    }

    final tripsRaw = _expectList(
      _expectNotNull(map['trips'], '$path.trips'),
      '$path.trips',
    );
    final trips = <TripDto>[];
    for (var i = 0; i < tripsRaw.length; i++) {
      trips.add(TripDto.fromJson(tripsRaw[i], '$path.trips[$i]'));
    }

    return TimetableDto(
      schemaVersion: _expectInt(
        _expectNotNull(map['schemaVersion'], '$path.schemaVersion'),
        '$path.schemaVersion',
      ),
      datasetVersion: _expectString(
        _expectNotNull(map['datasetVersion'], '$path.datasetVersion'),
        '$path.datasetVersion',
      ),
      isSampleData: _expectBool(
        _expectNotNull(map['isSampleData'], '$path.isSampleData'),
        '$path.isSampleData',
      ),
      stops: stops,
      routes: routes,
      trips: trips,
    );
  }
}
