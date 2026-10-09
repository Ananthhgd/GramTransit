import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/logging/app_logger.dart';
import 'package:gramtransit_passenger/features/transit/data/bundled_timetable_repository.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';

import '../../../helpers/fakes/fake_asset_bundle.dart';

void main() {
  group('BundledTimetableRepository', () {
    late FakeAssetBundle bundle;
    late AppLogger logger;
    late BundledTimetableRepository repo;

    setUp(() {
      bundle = FakeAssetBundle();
      logger = const AppLogger();
      repo = BundledTimetableRepository(
        bundle: bundle,
        logger: logger,
        assetPath: 'assets/transit/timetable.json',
      );
    });

    final validJson = '''
    {
      "schemaVersion": 1,
      "datasetVersion": "test",
      "isSampleData": true,
      "stops": [
        {"id": "s1", "name": {"en": "S1"}}
      ],
      "routes": [
        {"id": "r1", "shortName": {"en": "R1"}, "longName": {"en": "R1"}}
      ],
      "trips": [
        {
          "id": "t1",
          "routeId": "r1",
          "serviceDays": ["mon"],
          "stopTimes": [
            {"stopId": "s1", "arrivalTime": "10:00", "departureTime": "10:00"}
          ]
        }
      ]
    }
    ''';

    test('valid data -> Timetable and memoizes', () async {
      bundle = FakeAssetBundle(returnedString: validJson);
      repo = BundledTimetableRepository(bundle: bundle, logger: logger);

      final timetable = await repo.loadTimetable();
      expect(timetable, isA<Timetable>());
      expect(bundle.loadCount, 1);

      final timetable2 = await repo.loadTimetable();
      expect(timetable2, same(timetable));
      expect(bundle.loadCount, 1); // Not hit again
    });

    test('asset FlutterError -> DataFormatFailure', () async {
      bundle = FakeAssetBundle(thrownError: FlutterError('Asset not found'));
      repo = BundledTimetableRepository(bundle: bundle, logger: logger);

      await expectLater(
        () => repo.loadTimetable(),
        throwsA(isA<DataFormatFailure>()),
      );

      // failure not memoized, retry attempts load again
      await expectLater(
        () => repo.loadTimetable(),
        throwsA(isA<DataFormatFailure>()),
      );
      expect(bundle.loadCount, 2);
    });

    test('invalid JSON FormatException -> DataFormatFailure', () async {
      bundle = FakeAssetBundle(returnedString: '{ bad json');
      repo = BundledTimetableRepository(bundle: bundle, logger: logger);

      await expectLater(
        () => repo.loadTimetable(),
        throwsA(isA<DataFormatFailure>()),
      );
    });

    test('DTO TimetableFormatException -> DataFormatFailure', () async {
      bundle = FakeAssetBundle(returnedString: '{}'); // missing keys
      repo = BundledTimetableRepository(bundle: bundle, logger: logger);

      await expectLater(
        () => repo.loadTimetable(),
        throwsA(isA<DataFormatFailure>()),
      );
    });

    test('mapper TimetableFormatException -> DataFormatFailure', () async {
      final badSchema = validJson.replaceAll(
        '"schemaVersion": 1',
        '"schemaVersion": 2',
      );
      bundle = FakeAssetBundle(returnedString: badSchema);
      repo = BundledTimetableRepository(bundle: bundle, logger: logger);

      await expectLater(
        () => repo.loadTimetable(),
        throwsA(isA<DataFormatFailure>()),
      );
    });

    test(
      'unexpected exception propagates unchanged and is not DataFormatFailure',
      () async {
        bundle = FakeAssetBundle(
          thrownError: StateError('unexpected state error'),
        );
        repo = BundledTimetableRepository(bundle: bundle, logger: logger);

        await expectLater(
          () => repo.loadTimetable(),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
