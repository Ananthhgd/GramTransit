// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GramTransit';

  @override
  String get navHome => 'Home';

  @override
  String get navMore => 'More';

  @override
  String get homeWelcomeTitle => 'Welcome to GramTransit';

  @override
  String get homeWelcomeSubtitle => 'Bus timings for your village routes';

  @override
  String get homeSearchPlaceholder => 'Where are you going?';

  @override
  String get homeSearchComingSoon => 'Search is coming soon';

  @override
  String get homeUpcomingDeparturesTitle => 'Upcoming departures';

  @override
  String get homeUpcomingDeparturesEmptyTitle => 'No departures to show yet';

  @override
  String get homeUpcomingDeparturesEmptyMessage =>
      'Bus timetables will appear here once they are available.';

  @override
  String get moreTitle => 'More';

  @override
  String get moreSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsThemeLabel => 'Theme';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get routeNotFoundTitle => 'Page not found';

  @override
  String get routeNotFoundMessage =>
      'The page you\'re looking for doesn\'t exist.';

  @override
  String get routeNotFoundAction => 'Go to Home';
}
