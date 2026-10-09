import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/features/transit/data/timetable_dto.dart';
import 'package:gramtransit_passenger/features/transit/data/timetable_format_exception.dart';

void main() {
  group('TimetableDto', () {
    test('parses valid structural JSON', () {
      final json = {
        'schemaVersion': 1,
        'datasetVersion': 'test',
        'isSampleData': false,
        'stops': [
          {
            'id': 's1',
            'name': {'en': 'S1'},
          },
        ],
        'routes': [
          {
            'id': 'r1',
            'shortName': {'en': 'R1'},
            'longName': {'en': 'Route 1'},
          },
        ],
        'trips': [
          {
            'id': 't1',
            'routeId': 'r1',
            'serviceDays': ['mon'],
            'stopTimes': [
              {
                'stopId': 's1',
                'arrivalTime': '10:00',
                'departureTime': '10:05',
              },
            ],
          },
        ],
      };

      final dto = TimetableDto.fromJson(json);
      expect(dto.schemaVersion, 1);
      expect(dto.datasetVersion, 'test');
      expect(dto.isSampleData, false);
      expect(dto.stops.length, 1);
      expect(dto.routes.length, 1);
      expect(dto.trips.length, 1);
      expect(dto.trips.first.stopTimes.first.arrivalTime, '10:00');
    });

    test('rejects non-object root', () {
      expect(
        () => TimetableDto.fromJson([]),
        throwsA(
          isA<TimetableFormatException>().having((e) => e.path, 'path', r'$'),
        ),
      );
    });

    test('rejects missing required keys', () {
      final json = {
        'datasetVersion': 'test',
        'isSampleData': true,
        'stops': [],
        'routes': [],
        'trips': [],
      };
      expect(
        () => TimetableDto.fromJson(json),
        throwsA(
          isA<TimetableFormatException>().having(
            (e) => e.path,
            'path',
            r'$.schemaVersion',
          ),
        ),
      );
    });

    test('rejects wrong JSON types', () {
      final json = {
        'schemaVersion': '1', // string instead of int
        'datasetVersion': 'test',
        'isSampleData': false,
        'stops': [], 'routes': [], 'trips': [],
      };
      expect(
        () => TimetableDto.fromJson(json),
        throwsA(
          isA<TimetableFormatException>().having(
            (e) => e.path,
            'path',
            r'$.schemaVersion',
          ),
        ),
      );
    });

    test('rejects nested wrong types', () {
      final json = {
        'schemaVersion': 1,
        'datasetVersion': 'test',
        'isSampleData': false,
        'stops': [
          {
            'id': 123,
            'name': {'en': 'S1'},
          }, // id is int instead of string
        ],
        'routes': [],
        'trips': [],
      };
      expect(
        () => TimetableDto.fromJson(json),
        throwsA(
          isA<TimetableFormatException>().having(
            (e) => e.path,
            'path',
            r'$.stops[0].id',
          ),
        ),
      );
    });
  });
}
