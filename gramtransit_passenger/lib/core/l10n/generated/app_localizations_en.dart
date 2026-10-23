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
  String get homeStopSelectorLabel => 'Select stop';

  @override
  String get homeChooseStopPrompt =>
      'Choose a stop to see scheduled departures.';

  @override
  String get homeScheduledDisclosure =>
      'Scheduled times. Actual times may vary.';

  @override
  String get homeSampleDataNotice =>
      'Sample timetable for testing — not for real travel.';

  @override
  String get homeTimetableLoadError => 'The timetable could not be loaded.';

  @override
  String get homeNoStopsAvailable => 'No stops available';

  @override
  String homeNoUpcomingDepartures(String stop) {
    return 'No upcoming scheduled buses from $stop';
  }

  @override
  String homeNoMoreDeparturesForNow(String stop) {
    return 'No more scheduled buses from $stop for now';
  }

  @override
  String get homeNextScheduledBus => 'Next scheduled bus';

  @override
  String homeTripDestination(String destination) {
    return 'To $destination';
  }

  @override
  String homeTripRoute(String shortName, String longName) {
    return 'Route $shortName · $longName';
  }

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
  String get routeNotFoundTitle => 'Route not found';

  @override
  String get routeNotFoundMessage =>
      'This route isn\'t in the current timetable.';

  @override
  String get routeNotFoundAction => 'Go back';

  @override
  String get loadingLabel => 'Loading';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String get errorStorage => 'We couldn\'t save this on your device.';

  @override
  String get errorDataFormat => 'The timetable data could not be loaded.';

  @override
  String get errorUnexpected => 'Something went wrong. Please try again.';

  @override
  String get settingsThemeNotSaved =>
      'Theme changed, but it couldn\'t be saved. It will reset when you close the app.';

  @override
  String get homeTripCardOpenHint => 'Opens trip details';

  @override
  String get tripDetailsTitle => 'Trip details';

  @override
  String tripDetailsRouteLabel(String shortName) {
    return 'Route $shortName';
  }

  @override
  String tripDetailsOriginToDestination(String origin, String destination) {
    return '$origin → $destination';
  }

  @override
  String get tripDetailsRunsEveryDay => 'Runs every day';

  @override
  String tripDetailsRunsOn(String days) {
    return 'Runs $days';
  }

  @override
  String get tripDetailsScheduledTimesNote =>
      'Scheduled times. Actual times may vary.';

  @override
  String get tripDetailsStopTimesTitle => 'Scheduled stop times';

  @override
  String get tripDetailsFirstStop => 'First stop';

  @override
  String get tripDetailsLastStop => 'Last stop';

  @override
  String tripDetailsDeparts(String time) {
    return 'Departs $time';
  }

  @override
  String tripDetailsArrives(String time) {
    return 'Arrives $time';
  }

  @override
  String get tripDetailsNextDayMarker => '+1';

  @override
  String get tripDetailsNextDaySemantics => 'next day';

  @override
  String tripDetailsScheduledDepartureSemantics(String time) {
    return 'scheduled departure $time';
  }

  @override
  String tripDetailsScheduledArrivalSemantics(String time) {
    return 'scheduled arrival $time';
  }

  @override
  String get tripNotFoundTitle => 'Trip not found';

  @override
  String get tripNotFoundMessage =>
      'This trip isn\'t in the current timetable.';

  @override
  String get tripNotFoundAction => 'Go to Home';

  @override
  String get journeySearchTitle => 'Journey search';

  @override
  String get journeySearchFromLabel => 'From';

  @override
  String get journeySearchFromPlaceholder => 'Choose starting stop';

  @override
  String get journeySearchToLabel => 'To';

  @override
  String get journeySearchToPlaceholder => 'Choose destination stop';

  @override
  String get journeySearchSwapStops => 'Swap stops';

  @override
  String journeySearchClearStop(String stopType) {
    return 'Clear $stopType stop';
  }

  @override
  String get journeySearchChooseStopsPrompt =>
      'Select a starting stop and destination to view scheduled journeys.';

  @override
  String get journeySearchNoDirectJourneysTitle =>
      'No direct scheduled journeys';

  @override
  String get journeySearchNoDirectJourneysMessage =>
      'No direct scheduled buses were found between these stops in the current timetable.';

  @override
  String get journeySearchNoMoreJourneysToday =>
      'No more scheduled journeys for today';

  @override
  String get journeySearchNextScheduledJourneys => 'Next scheduled journeys';

  @override
  String get journeySearchNoStopsFound => 'No stops found';

  @override
  String get journeyDurationLessThanOneMinute => 'Less than 1 min';

  @override
  String journeyDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String journeyDurationHours(int hours) {
    return '$hours hr';
  }

  @override
  String journeyDurationHoursMinutes(int hours, int minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String journeyTripRoute(String shortName, String destination) {
    return 'Route $shortName · To $destination';
  }

  @override
  String journeyTripRouteFallback(String shortName, String longName) {
    return 'Route $shortName · $longName';
  }

  @override
  String get stopsTitle => 'Stops';

  @override
  String get stopsSearchHint => 'Search stops';

  @override
  String get stopsClearSearch => 'Clear search';

  @override
  String get stopsNoStopsFound => 'No stops found';

  @override
  String get stopDetailsTitle => 'Stop details';

  @override
  String get stopNotFoundTitle => 'Stop not found';

  @override
  String get stopNotFoundMessage =>
      'This stop isn\'t in the current timetable.';

  @override
  String get stopNotFoundAction => 'Go to Home';

  @override
  String get stopPlanJourneyFromHere => 'Plan journey from here';

  @override
  String get stopRoutesServingTitle => 'Routes serving this stop';

  @override
  String get stopNoRoutesServing => 'No routes currently serve this stop';

  @override
  String get stopUpcomingDeparturesTitle => 'Upcoming departures';

  @override
  String get routesTitle => 'Routes';

  @override
  String get routesNoRoutesAvailable => 'No routes available';

  @override
  String get routeDetailsTitle => 'Route details';

  @override
  String get routeNoScheduledTrips =>
      'No scheduled trips available for this route.';

  @override
  String get routeStopsHeading => 'Stops';

  @override
  String get routeScheduledTripsHeading => 'Scheduled trips';

  @override
  String routeVariantTitle(int index, String origin, String destination) {
    return 'Variant $index: $origin to $destination';
  }

  @override
  String routeStopSequenceItemSemantics(
    int position,
    int total,
    String stopName,
  ) {
    return 'Stop $position of $total: $stopName';
  }

  @override
  String routeDepartureEndpointSemantics(String time) {
    return 'Departs $time';
  }

  @override
  String routeArrivalEndpointSemantics(String time) {
    return 'Arrives $time';
  }
}
