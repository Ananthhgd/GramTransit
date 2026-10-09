import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/features/transit/data/timetable_dto.dart';
import 'package:gramtransit_passenger/features/transit/data/timetable_format_exception.dart';
import 'package:gramtransit_passenger/features/transit/data/timetable_mapper.dart';

void main() {
  group('TimetableMapper', () {
    TimetableDto createValidDto() {
      return TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: [
          const StopDto(
            id: 's1',
            name: LocalizedTextDto(en: 'S1'),
          ),
          const StopDto(
            id: 's2',
            name: LocalizedTextDto(en: 'S2'),
          ),
        ],
        routes: [
          const RouteDto(
            id: 'r1',
            shortName: LocalizedTextDto(en: 'R1'),
            longName: LocalizedTextDto(en: 'Route 1'),
          ),
        ],
        trips: [
          const TripDto(
            id: 't1',
            routeId: 'r1',
            serviceDays: ['mon', 'tue'],
            stopTimes: [
              StopTimeDto(
                stopId: 's1',
                arrivalTime: '08:00',
                departureTime: '08:05',
              ),
              StopTimeDto(
                stopId: 's2',
                arrivalTime: '08:20',
                departureTime: '08:25',
              ),
            ],
          ),
        ],
      );
    }

    test('valid DTO maps to Timetable', () {
      final dto = createValidDto();
      final timetable = TimetableMapper.toDomain(dto);
      expect(timetable.stops.length, 2);
      expect(timetable.routes.length, 1);
      expect(timetable.trips.length, 1);
      expect(timetable.info.datasetVersion, isNotEmpty);
    });

    test('rejects unsupported schemaVersion', () {
      final dto = TimetableDto(
        schemaVersion: 2,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: [],
        routes: [],
        trips: [],
      );
      expect(
        () => TimetableMapper.toDomain(dto),
        throwsA(
          isA<TimetableFormatException>().having(
            (e) => e.path,
            'path',
            r'$.schemaVersion',
          ),
        ),
      );
    });

    test('rejects empty datasetVersion', () {
      final dto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: '   ',
        isSampleData: true,
        stops: [],
        routes: [],
        trips: [],
      );
      expect(
        () => TimetableMapper.toDomain(dto),
        throwsA(
          isA<TimetableFormatException>().having(
            (e) => e.path,
            'path',
            r'$.datasetVersion',
          ),
        ),
      );
    });

    test('rejects duplicate stop ID', () {
      final dto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: [
          const StopDto(
            id: 's1',
            name: LocalizedTextDto(en: 'S1'),
          ),
          const StopDto(
            id: 's1',
            name: LocalizedTextDto(en: 'S1-dup'),
          ),
        ],
        routes: [],
        trips: [],
      );
      expect(
        () => TimetableMapper.toDomain(dto),
        throwsA(
          isA<TimetableFormatException>().having(
            (e) => e.path,
            'path',
            r'$.stops[1].id',
          ),
        ),
      );
    });

    test('rejects duplicate route ID', () {
      final dto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: [],
        routes: [
          const RouteDto(
            id: 'r1',
            shortName: LocalizedTextDto(en: 'R1'),
            longName: LocalizedTextDto(en: 'R1'),
          ),
          const RouteDto(
            id: 'r1',
            shortName: LocalizedTextDto(en: 'R2'),
            longName: LocalizedTextDto(en: 'R2'),
          ),
        ],
        trips: [],
      );
      expect(
        () => TimetableMapper.toDomain(dto),
        throwsA(
          isA<TimetableFormatException>().having(
            (e) => e.path,
            'path',
            r'$.routes[1].id',
          ),
        ),
      );
    });

    test('rejects duplicate trip ID', () {
      final dto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: [
          const StopDto(
            id: 's1',
            name: LocalizedTextDto(en: 'S1'),
          ),
          const StopDto(
            id: 's2',
            name: LocalizedTextDto(en: 'S2'),
          ),
        ],
        routes: [
          const RouteDto(
            id: 'r1',
            shortName: LocalizedTextDto(en: 'R1'),
            longName: LocalizedTextDto(en: 'R1'),
          ),
        ],
        trips: [
          const TripDto(
            id: 't1',
            routeId: 'r1',
            serviceDays: ['mon'],
            stopTimes: [
              StopTimeDto(
                stopId: 's1',
                arrivalTime: '08:00',
                departureTime: '08:00',
              ),
              StopTimeDto(
                stopId: 's2',
                arrivalTime: '09:00',
                departureTime: '09:00',
              ),
            ],
          ),
          const TripDto(
            id: 't1',
            routeId: 'r1',
            serviceDays: ['mon'],
            stopTimes: [
              StopTimeDto(
                stopId: 's1',
                arrivalTime: '10:00',
                departureTime: '10:00',
              ),
              StopTimeDto(
                stopId: 's2',
                arrivalTime: '11:00',
                departureTime: '11:00',
              ),
            ],
          ),
        ],
      );
      expect(
        () => TimetableMapper.toDomain(dto),
        throwsA(
          isA<TimetableFormatException>().having(
            (e) => e.path,
            'path',
            r'$.trips[1].id',
          ),
        ),
      );
    });

    test('rejects missing/empty English name', () {
      final dto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: [
          const StopDto(
            id: 's1',
            name: LocalizedTextDto(en: '  '),
          ),
        ],
        routes: [],
        trips: [],
      );
      expect(
        () => TimetableMapper.toDomain(dto),
        throwsA(
          isA<TimetableFormatException>().having(
            (e) => e.path,
            'path',
            r'$.stops[0].name.en',
          ),
        ),
      );
    });

    test('rejects malformed time string', () {
      final dto = createValidDto();
      final trips = List<TripDto>.from(dto.trips);
      trips[0] = TripDto(
        id: 't1',
        routeId: 'r1',
        serviceDays: ['mon'],
        stopTimes: [
          const StopTimeDto(
            stopId: 's1',
            arrivalTime: '8:00',
            departureTime: '08:05',
          ),
        ],
      );
      final badDto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: dto.stops,
        routes: dto.routes,
        trips: trips,
      );
      expect(
        () => TimetableMapper.toDomain(badDto),
        throwsA(isA<TimetableFormatException>()),
      );
    });

    test('rejects hour > 47', () {
      final dto = createValidDto();
      final trips = List<TripDto>.from(dto.trips);
      trips[0] = TripDto(
        id: 't1',
        routeId: 'r1',
        serviceDays: ['mon'],
        stopTimes: [
          const StopTimeDto(
            stopId: 's1',
            arrivalTime: '48:00',
            departureTime: '48:05',
          ),
        ],
      );
      final badDto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: dto.stops,
        routes: dto.routes,
        trips: trips,
      );
      expect(
        () => TimetableMapper.toDomain(badDto),
        throwsA(isA<TimetableFormatException>()),
      );
    });

    test('rejects invalid minute', () {
      final dto = createValidDto();
      final trips = List<TripDto>.from(dto.trips);
      trips[0] = TripDto(
        id: 't1',
        routeId: 'r1',
        serviceDays: ['mon'],
        stopTimes: [
          const StopTimeDto(
            stopId: 's1',
            arrivalTime: '10:60',
            departureTime: '10:61',
          ),
        ],
      );
      final badDto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: dto.stops,
        routes: dto.routes,
        trips: trips,
      );
      expect(
        () => TimetableMapper.toDomain(badDto),
        throwsA(isA<TimetableFormatException>()),
      );
    });

    test('rejects empty service days', () {
      final dto = createValidDto();
      final trips = List<TripDto>.from(dto.trips);
      trips[0] = TripDto(
        id: 't1',
        routeId: 'r1',
        serviceDays: [],
        stopTimes: trips[0].stopTimes,
      );
      final badDto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: dto.stops,
        routes: dto.routes,
        trips: trips,
      );
      expect(
        () => TimetableMapper.toDomain(badDto),
        throwsA(isA<TimetableFormatException>()),
      );
    });

    test('rejects unknown day token', () {
      final dto = createValidDto();
      final trips = List<TripDto>.from(dto.trips);
      trips[0] = TripDto(
        id: 't1',
        routeId: 'r1',
        serviceDays: ['funday'],
        stopTimes: trips[0].stopTimes,
      );
      final badDto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: dto.stops,
        routes: dto.routes,
        trips: trips,
      );
      expect(
        () => TimetableMapper.toDomain(badDto),
        throwsA(isA<TimetableFormatException>()),
      );
    });

    test('rejects duplicate day token', () {
      final dto = createValidDto();
      final trips = List<TripDto>.from(dto.trips);
      trips[0] = TripDto(
        id: 't1',
        routeId: 'r1',
        serviceDays: ['mon', 'mon'],
        stopTimes: trips[0].stopTimes,
      );
      final badDto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: dto.stops,
        routes: dto.routes,
        trips: trips,
      );
      expect(
        () => TimetableMapper.toDomain(badDto),
        throwsA(isA<TimetableFormatException>()),
      );
    });

    test('rejects unknown route reference', () {
      final dto = createValidDto();
      final trips = List<TripDto>.from(dto.trips);
      trips[0] = TripDto(
        id: 't1',
        routeId: 'r2',
        serviceDays: ['mon'],
        stopTimes: trips[0].stopTimes,
      );
      final badDto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: dto.stops,
        routes: dto.routes,
        trips: trips,
      );
      expect(
        () => TimetableMapper.toDomain(badDto),
        throwsA(isA<TimetableFormatException>()),
      );
    });

    test('rejects unknown stop reference', () {
      final dto = createValidDto();
      final trips = List<TripDto>.from(dto.trips);
      trips[0] = TripDto(
        id: 't1',
        routeId: 'r1',
        serviceDays: ['mon'],
        stopTimes: [
          const StopTimeDto(
            stopId: 's99',
            arrivalTime: '08:00',
            departureTime: '08:05',
          ),
        ],
      );
      final badDto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: dto.stops,
        routes: dto.routes,
        trips: trips,
      );
      expect(
        () => TimetableMapper.toDomain(badDto),
        throwsA(isA<TimetableFormatException>()),
      );
    });

    test('rejects insufficient stop times', () {
      final dto = createValidDto();
      final trips = List<TripDto>.from(dto.trips);
      trips[0] = TripDto(
        id: 't1',
        routeId: 'r1',
        serviceDays: ['mon'],
        stopTimes: [],
      );
      final badDto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: dto.stops,
        routes: dto.routes,
        trips: trips,
      );
      expect(
        () => TimetableMapper.toDomain(badDto),
        throwsA(isA<TimetableFormatException>()),
      );
    });

    test('rejects repeated stop in trip', () {
      final dto = createValidDto();
      final trips = List<TripDto>.from(dto.trips);
      trips[0] = TripDto(
        id: 't1',
        routeId: 'r1',
        serviceDays: ['mon'],
        stopTimes: [
          const StopTimeDto(
            stopId: 's1',
            arrivalTime: '08:00',
            departureTime: '08:05',
          ),
          const StopTimeDto(
            stopId: 's1',
            arrivalTime: '08:20',
            departureTime: '08:25',
          ),
        ],
      );
      final badDto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: dto.stops,
        routes: dto.routes,
        trips: trips,
      );
      expect(
        () => TimetableMapper.toDomain(badDto),
        throwsA(isA<TimetableFormatException>()),
      );
    });

    test('rejects departure before arrival', () {
      final dto = createValidDto();
      final trips = List<TripDto>.from(dto.trips);
      trips[0] = TripDto(
        id: 't1',
        routeId: 'r1',
        serviceDays: ['mon'],
        stopTimes: [
          const StopTimeDto(
            stopId: 's1',
            arrivalTime: '08:05',
            departureTime: '08:00',
          ),
          const StopTimeDto(
            stopId: 's2',
            arrivalTime: '08:20',
            departureTime: '08:25',
          ),
        ],
      );
      final badDto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: dto.stops,
        routes: dto.routes,
        trips: trips,
      );
      expect(
        () => TimetableMapper.toDomain(badDto),
        throwsA(isA<TimetableFormatException>()),
      );
    });

    test('rejects invalid cross-stop chronological order', () {
      final dto = createValidDto();
      final trips = List<TripDto>.from(dto.trips);
      trips[0] = TripDto(
        id: 't1',
        routeId: 'r1',
        serviceDays: ['mon'],
        stopTimes: [
          const StopTimeDto(
            stopId: 's1',
            arrivalTime: '08:00',
            departureTime: '08:25',
          ),
          const StopTimeDto(
            stopId: 's2',
            arrivalTime: '08:20',
            departureTime: '08:30',
          ),
        ],
      );
      final badDto = TimetableDto(
        schemaVersion: 1,
        datasetVersion: 'v1',
        isSampleData: true,
        stops: dto.stops,
        routes: dto.routes,
        trips: trips,
      );
      expect(
        () => TimetableMapper.toDomain(badDto),
        throwsA(isA<TimetableFormatException>()),
      );
    });
  });
}
