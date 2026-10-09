/// Represents invalid external timetable data.
class TimetableFormatException implements Exception {
  /// The path where the format error occurred (e.g., `trips[0].serviceDays[1]`).
  final String path;

  /// A developer-facing description of the format error.
  final String message;

  const TimetableFormatException(this.path, this.message);

  @override
  String toString() => 'TimetableFormatException at "$path": $message';
}
