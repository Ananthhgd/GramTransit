import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/core/logging/app_logger.dart';
import 'package:gramtransit_passenger/features/transit/data/bundled_timetable_repository.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled asset loads successfully through repository', () async {
    final repo = BundledTimetableRepository(
      bundle: rootBundle,
      logger: const AppLogger(),
      assetPath: 'assets/transit/timetable.json',
    );

    final timetable = await repo.loadTimetable();

    expect(timetable, isA<Timetable>());
    expect(timetable.info.datasetVersion, isNotEmpty);
    expect(timetable.stops, isNotEmpty);
    expect(timetable.routes, isNotEmpty);
    expect(timetable.trips, isNotEmpty);
  });
}
