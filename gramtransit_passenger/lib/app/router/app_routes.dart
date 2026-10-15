/// Route names and full paths for the GramTransit Passenger application.
///
/// Names are used for named navigation via [GoRouter.goNamed].
/// Full paths are provided for documentation and location-checking purposes.
abstract final class AppRoutes {
  // ── Names ──────────────────────────────────────────────────────────────────

  static const String home = 'home';
  static const String more = 'more';
  static const String settings = 'settings';
  static const String tripDetails = 'tripDetails';

  // ── Full paths (reference / location checks) ───────────────────────────────

  static const String homePath = '/home';
  static const String morePath = '/more';
  static const String settingsPath = '/more/settings';
  static const String tripDetailsPath = '/trips/:tripId';
}
