abstract class _StringId {
  final String value;
  const _StringId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _StringId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => value;
}

final class StopId extends _StringId {
  StopId(String value) : super(value) {
    if (value.trim().isEmpty) throw ArgumentError('StopId cannot be empty');
  }
}

final class RouteId extends _StringId {
  RouteId(String value) : super(value) {
    if (value.trim().isEmpty) throw ArgumentError('RouteId cannot be empty');
  }
}

final class TripId extends _StringId {
  TripId(String value) : super(value) {
    if (value.trim().isEmpty) throw ArgumentError('TripId cannot be empty');
  }
}
