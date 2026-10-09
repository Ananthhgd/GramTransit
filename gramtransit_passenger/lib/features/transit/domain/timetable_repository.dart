import 'transit_models.dart';

/// Repository contract for loading transit timetables.
abstract interface class TimetableRepository {
  /// Loads and returns a fully validated [Timetable].
  ///
  /// Known data format or parsing issues surface as DataFormatFailure.
  /// Unexpected exceptions propagate unchanged.
  Future<Timetable> loadTimetable();
}
