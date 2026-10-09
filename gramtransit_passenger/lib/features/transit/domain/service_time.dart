final class ServiceTime implements Comparable<ServiceTime> {
  final int hour;
  final int minute;

  ServiceTime({required this.hour, required this.minute}) {
    if (hour < 0 || hour >= 48) {
      throw ArgumentError('hour must be 0..47, was $hour');
    }
    if (minute < 0 || minute >= 60) {
      throw ArgumentError('minute must be 0..59, was $minute');
    }
  }

  factory ServiceTime.parse(String time) {
    final parts = time.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid ServiceTime format: $time');
    }
    return ServiceTime(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Converts this ServiceTime to an absolute DateTime based on a given [serviceDate].
  /// [serviceDate] should typically be a DateTime with time set to 00:00:00.
  DateTime toDateTime(DateTime serviceDate) {
    return DateTime(
      serviceDate.year,
      serviceDate.month,
      serviceDate.day,
      hour,
      minute,
    );
  }

  int get inMinutes => hour * 60 + minute;

  @override
  int compareTo(ServiceTime other) => inMinutes.compareTo(other.inMinutes);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceTime &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
