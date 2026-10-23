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
  static const String journeys = 'journeys';
  static const String stops = 'stops';
  static const String stopDetails = 'stopDetails';
  static const String routes = 'routes';
  static const String routeDetails = 'routeDetails';

  // ── Full paths (reference / location checks) ───────────────────────────────

  static const String homePath = '/home';
  static const String morePath = '/more';
  static const String settingsPath = '/more/settings';
  static const String tripDetailsPath = '/trips/:tripId';
  static const String journeysPath = '/journeys';
  static const String stopsPath = '/stops';
  static const String stopDetailsPath = '/stops/:stopId';
  static const String routesPath = '/routes';
  static const String routeDetailsPath = '/routes/:routeId';
}
