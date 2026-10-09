final class ServiceDays {
  /// Whether the service operates on Monday (1) through Sunday (7).
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final bool sunday;

  const ServiceDays({
    this.monday = false,
    this.tuesday = false,
    this.wednesday = false,
    this.thursday = false,
    this.friday = false,
    this.saturday = false,
    this.sunday = false,
  });

  /// Returns true if this service operates on the given [date].
  bool operatesOn(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return monday;
      case DateTime.tuesday:
        return tuesday;
      case DateTime.wednesday:
        return wednesday;
      case DateTime.thursday:
        return thursday;
      case DateTime.friday:
        return friday;
      case DateTime.saturday:
        return saturday;
      case DateTime.sunday:
        return sunday;
      default:
        return false;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceDays &&
          runtimeType == other.runtimeType &&
          monday == other.monday &&
          tuesday == other.tuesday &&
          wednesday == other.wednesday &&
          thursday == other.thursday &&
          friday == other.friday &&
          saturday == other.saturday &&
          sunday == other.sunday;

  @override
  int get hashCode => Object.hash(
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
    sunday,
  );
}
