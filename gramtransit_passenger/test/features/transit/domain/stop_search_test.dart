import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/stop_search.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';

void main() {
  group('normalizeStopSearch', () {
    test('lowercases text', () {
      expect(normalizeStopSearch('CENTRAL STATION'), 'central station');
    });

    test(
      'deletes periods, straight single quotes, and curly single quotes',
      () {
        expect(normalizeStopSearch("St. John's / Mary’s"), 'st johns marys');
      },
    );

    test('replaces hyphens, en-dashes, slashes, commas, and parentheses with spaces', () {
      expect(
        normalizeStopSearch('North-West – City/Town, (Hub)'),
        'north west city town hub',
      );
    });

    test('trims leading/trailing whitespace and collapses repeated internal whitespace', () {
      expect(
        normalizeStopSearch('   Central    Bus    Stand   '),
        'central bus stand',
      );
    });

    test('handles empty or whitespace-only string', () {
      expect(normalizeStopSearch(''), '');
      expect(normalizeStopSearch('   '), '');
      expect(normalizeStopSearch(' . - / , ( ) ’ '), '');
    });
  });

  group('searchStops', () {
    late Timetable timetable;

    setUp(() {
      timetable = Timetable(
        info: TimetableInfo(datasetVersion: '1', isSampleData: true),
        stops: [
          TransitStop(
            id: StopId('stop_1'),
            name: LocalizedText(english: 'Market'),
          ),
          TransitStop(
            id: StopId('stop_2'),
            name: LocalizedText(english: 'Market Road'),
          ),
          TransitStop(
            id: StopId('stop_3'),
            name: LocalizedText(english: 'New Market'),
          ),
          TransitStop(
            id: StopId('stop_4'),
            name: LocalizedText(english: 'Supermarket'),
          ),
          TransitStop(
            id: StopId('stop_5'),
            name: LocalizedText(english: 'City Center'),
          ),
          TransitStop(
            id: StopId('stop_dup_1'),
            name: LocalizedText(english: 'Duplicate Name'),
          ),
          TransitStop(
            id: StopId('stop_dup_2'),
            name: LocalizedText(english: 'Duplicate Name'),
          ),
          TransitStop(
            id: StopId('stop_punct'),
            name: LocalizedText(english: "St. John's / Mary's (North-East)"),
          ),
        ],
        routes: [],
        trips: [],
      );
    });

    test(
      'empty query returns all non-excluded stops in original timetable order',
      () {
        final results = searchStops(timetable: timetable, query: '');

        expect(results.length, timetable.stops.length);
        expect(results.map((s) => s.id), timetable.stops.map((s) => s.id));
      },
    );

    test('whitespace-only query returns all non-excluded stops in original timetable order', () {
      final results = searchStops(timetable: timetable, query: '   ');

      expect(results.length, timetable.stops.length);
      expect(results.map((s) => s.id), timetable.stops.map((s) => s.id));
    });

    test('excluded StopId is omitted from results', () {
      final results = searchStops(
        timetable: timetable,
        query: '',
        excludedStopId: StopId('stop_1'),
      );

      expect(results.any((s) => s.id == StopId('stop_1')), isFalse);
      expect(results.length, timetable.stops.length - 1);
    });

    test('case-insensitive matching', () {
      final results = searchStops(timetable: timetable, query: 'market');
      final upperResults = searchStops(timetable: timetable, query: 'MARKET');

      expect(results.map((s) => s.id), upperResults.map((s) => s.id));
    });

    test('deletion and replacement of punctuation in query and stop names', () {
      final results = searchStops(
        timetable: timetable,
        query: "st johns marys north east",
      );

      expect(results.length, 1);
      expect(results.first.id, StopId('stop_punct'));
    });

    test('four ranking buckets: exact, starts-with name, starts-with word, other substring', () {
      // Query "market":
      // Bucket 1 (exact): "Market" (stop_1)
      // Bucket 2 (starts-with whole name): "Market Road" (stop_2)
      // Bucket 3 (starts-with any word): "New Market" (stop_3, word "market")
      // Bucket 4 (other substring): "Supermarket" (stop_4)
      final results = searchStops(timetable: timetable, query: 'market');

      expect(results.length, 4);
      expect(results[0].id, StopId('stop_1'));
      expect(results[1].id, StopId('stop_2'));
      expect(results[2].id, StopId('stop_3'));
      expect(results[3].id, StopId('stop_4'));
    });

    test('stable timetable ordering inside equal bucket', () {
      // Both "Duplicate Name" stops match exact query "duplicate name"
      final results = searchStops(
        timetable: timetable,
        query: 'duplicate name',
      );

      expect(results.length, 2);
      expect(results[0].id, StopId('stop_dup_1'));
      expect(results[1].id, StopId('stop_dup_2'));
    });

    test('duplicate English names are both retained as separate TransitStop instances', () {
      final results = searchStops(timetable: timetable, query: 'duplicate');

      expect(results.length, 2);
      expect(results[0].id, StopId('stop_dup_1'));
      expect(results[1].id, StopId('stop_dup_2'));
      expect(results[0].name.english, 'Duplicate Name');
      expect(results[1].name.english, 'Duplicate Name');
    });

    test('nonmatching stops are excluded', () {
      final results = searchStops(timetable: timetable, query: 'nonexistent');

      expect(results, isEmpty);
    });

    test('excludedStopId is also omitted when query is non-empty', () {
      final results = searchStops(
        timetable: timetable,
        query: 'market',
        excludedStopId: StopId('stop_1'),
      );

      expect(results.length, 3);
      expect(results.any((s) => s.id == StopId('stop_1')), isFalse);
      expect(results[0].id, StopId('stop_2'));
      expect(results[1].id, StopId('stop_3'));
      expect(results[2].id, StopId('stop_4'));
    });
  });
}
