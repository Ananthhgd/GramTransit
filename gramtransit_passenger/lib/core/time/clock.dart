abstract interface class Clock {
  /// Returns the current date and time.
  DateTime now();
}

/// Production implementation of [Clock] that uses the system wall clock.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
