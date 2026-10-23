import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The application title displayed in the OS task switcher.
  ///
  /// In en, this message translates to:
  /// **'GramTransit'**
  String get appTitle;

  /// Bottom navigation bar label for the Home tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation bar label for the More tab.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// Welcome heading displayed at the top of the Home screen.
  ///
  /// In en, this message translates to:
  /// **'Welcome to GramTransit'**
  String get homeWelcomeTitle;

  /// Subtitle below the Home screen welcome heading.
  ///
  /// In en, this message translates to:
  /// **'Bus timings for your village routes'**
  String get homeWelcomeSubtitle;

  /// Placeholder text shown inside the non-functional search entry on the Home screen.
  ///
  /// In en, this message translates to:
  /// **'Where are you going?'**
  String get homeSearchPlaceholder;

  /// Accessibility label for the non-functional search placeholder, communicating its future intent to assistive technology.
  ///
  /// In en, this message translates to:
  /// **'Search is coming soon'**
  String get homeSearchComingSoon;

  /// Section heading for the upcoming departures area on the Home screen.
  ///
  /// In en, this message translates to:
  /// **'Upcoming departures'**
  String get homeUpcomingDeparturesTitle;

  /// Label for the stop selector dropdown on the Home screen.
  ///
  /// In en, this message translates to:
  /// **'Select stop'**
  String get homeStopSelectorLabel;

  /// Prompt shown when timetable data is loaded but no stop has been selected.
  ///
  /// In en, this message translates to:
  /// **'Choose a stop to see scheduled departures.'**
  String get homeChooseStopPrompt;

  /// Persistent disclosure explaining that departure times are scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled times. Actual times may vary.'**
  String get homeScheduledDisclosure;

  /// Notice displayed when the timetable contains sample testing data.
  ///
  /// In en, this message translates to:
  /// **'Sample timetable for testing — not for real travel.'**
  String get homeSampleDataNotice;

  /// Error message displayed when the timetable fails to load.
  ///
  /// In en, this message translates to:
  /// **'The timetable could not be loaded.'**
  String get homeTimetableLoadError;

  /// Empty state title displayed when the loaded timetable contains no stops.
  ///
  /// In en, this message translates to:
  /// **'No stops available'**
  String get homeNoStopsAvailable;

  /// Message displayed when there are no scheduled buses remaining for the selected stop.
  ///
  /// In en, this message translates to:
  /// **'No upcoming scheduled buses from {stop}'**
  String homeNoUpcomingDepartures(String stop);

  /// Message displayed when there are no current departures remaining for the selected stop, but later departures exist.
  ///
  /// In en, this message translates to:
  /// **'No more scheduled buses from {stop} for now'**
  String homeNoMoreDeparturesForNow(String stop);

  /// Heading for nextLater departures when current departures are empty.
  ///
  /// In en, this message translates to:
  /// **'Next scheduled bus'**
  String get homeNextScheduledBus;

  /// Secondary line on an upcoming trip card showing the destination.
  ///
  /// In en, this message translates to:
  /// **'To {destination}'**
  String homeTripDestination(String destination);

  /// Tertiary line on an upcoming trip card showing route short and long names.
  ///
  /// In en, this message translates to:
  /// **'Route {shortName} · {longName}'**
  String homeTripRoute(String shortName, String longName);

  /// AppBar title for the More screen.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// Label for the Settings entry in the More screen list.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get moreSettings;

  /// AppBar title for the Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Section heading for appearance-related settings.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceSection;

  /// Label for the theme-selection control in Settings.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeLabel;

  /// Theme mode option: follow the device system setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// Theme mode option: always use the light theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// Theme mode option: always use the dark theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// Title for the empty state when a requested route cannot be found.
  ///
  /// In en, this message translates to:
  /// **'Route not found'**
  String get routeNotFoundTitle;

  /// Message explaining that the requested route was not found in the timetable.
  ///
  /// In en, this message translates to:
  /// **'This route isn\'t in the current timetable.'**
  String get routeNotFoundMessage;

  /// Button label to navigate back from the route-not-found state.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get routeNotFoundAction;

  /// Accessible label for a loading indicator, read by screen readers while content is being fetched.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingLabel;

  /// Label for a retry button shown after an error.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// Error message shown when a storage/persistence operation fails.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save this on your device.'**
  String get errorStorage;

  /// Error message shown when the offline timetable data is malformed or unreadable.
  ///
  /// In en, this message translates to:
  /// **'The timetable data could not be loaded.'**
  String get errorDataFormat;

  /// Generic error message shown when an unexpected failure occurs.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnexpected;

  /// SnackBar message shown when the theme is changed successfully in memory but the preference could not be persisted to storage.
  ///
  /// In en, this message translates to:
  /// **'Theme changed, but it couldn\'t be saved. It will reset when you close the app.'**
  String get settingsThemeNotSaved;

  /// Accessibility hint for the upcoming trip card button indicating that tapping it opens trip details.
  ///
  /// In en, this message translates to:
  /// **'Opens trip details'**
  String get homeTripCardOpenHint;

  /// AppBar title for the Trip Details screen.
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get tripDetailsTitle;

  /// Route label in Trip Details header.
  ///
  /// In en, this message translates to:
  /// **'Route {shortName}'**
  String tripDetailsRouteLabel(String shortName);

  /// Origin and destination pair in Trip Details header.
  ///
  /// In en, this message translates to:
  /// **'{origin} → {destination}'**
  String tripDetailsOriginToDestination(String origin, String destination);

  /// Service days text when the trip runs on all seven days.
  ///
  /// In en, this message translates to:
  /// **'Runs every day'**
  String get tripDetailsRunsEveryDay;

  /// Service days text when the trip runs on specific days of the week.
  ///
  /// In en, this message translates to:
  /// **'Runs {days}'**
  String tripDetailsRunsOn(String days);

  /// Scheduled times disclosure note on the Trip Details screen.
  ///
  /// In en, this message translates to:
  /// **'Scheduled times. Actual times may vary.'**
  String get tripDetailsScheduledTimesNote;

  /// Section heading for the ordered list of scheduled stop times.
  ///
  /// In en, this message translates to:
  /// **'Scheduled stop times'**
  String get tripDetailsStopTimesTitle;

  /// Label indicating the first stop in the trip sequence.
  ///
  /// In en, this message translates to:
  /// **'First stop'**
  String get tripDetailsFirstStop;

  /// Label indicating the last stop in the trip sequence.
  ///
  /// In en, this message translates to:
  /// **'Last stop'**
  String get tripDetailsLastStop;

  /// Departure time label for a stop.
  ///
  /// In en, this message translates to:
  /// **'Departs {time}'**
  String tripDetailsDeparts(String time);

  /// Arrival time label for a stop.
  ///
  /// In en, this message translates to:
  /// **'Arrives {time}'**
  String tripDetailsArrives(String time);

  /// Visible marker for times on the next day.
  ///
  /// In en, this message translates to:
  /// **'+1'**
  String get tripDetailsNextDayMarker;

  /// Accessibility label for next day time indication.
  ///
  /// In en, this message translates to:
  /// **'next day'**
  String get tripDetailsNextDaySemantics;

  /// Accessibility semantic text for scheduled departure time.
  ///
  /// In en, this message translates to:
  /// **'scheduled departure {time}'**
  String tripDetailsScheduledDepartureSemantics(String time);

  /// Accessibility semantic text for scheduled arrival time.
  ///
  /// In en, this message translates to:
  /// **'scheduled arrival {time}'**
  String tripDetailsScheduledArrivalSemantics(String time);

  /// Empty state title when a trip cannot be found in the timetable.
  ///
  /// In en, this message translates to:
  /// **'Trip not found'**
  String get tripNotFoundTitle;

  /// Empty state message when a trip cannot be found in the timetable.
  ///
  /// In en, this message translates to:
  /// **'This trip isn\'t in the current timetable.'**
  String get tripNotFoundMessage;

  /// Button label to navigate back to Home from the trip not found state.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get tripNotFoundAction;

  /// AppBar title for the Journey Search screen.
  ///
  /// In en, this message translates to:
  /// **'Journey search'**
  String get journeySearchTitle;

  /// Label for the boarding stop selector on the Journey Search screen.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get journeySearchFromLabel;

  /// Placeholder text for the boarding stop selector when no stop is selected.
  ///
  /// In en, this message translates to:
  /// **'Choose starting stop'**
  String get journeySearchFromPlaceholder;

  /// Label for the alighting/destination stop selector on the Journey Search screen.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get journeySearchToLabel;

  /// Placeholder text for the alighting/destination stop selector when no stop is selected.
  ///
  /// In en, this message translates to:
  /// **'Choose destination stop'**
  String get journeySearchToPlaceholder;

  /// Accessibility label and tooltip for the swap stops button.
  ///
  /// In en, this message translates to:
  /// **'Swap stops'**
  String get journeySearchSwapStops;

  /// Accessibility label for clearing a selected stop.
  ///
  /// In en, this message translates to:
  /// **'Clear {stopType} stop'**
  String journeySearchClearStop(String stopType);

  /// Prompt displayed before both boarding and destination stops have been selected.
  ///
  /// In en, this message translates to:
  /// **'Select a starting stop and destination to view scheduled journeys.'**
  String get journeySearchChooseStopsPrompt;

  /// Empty state title when no direct scheduled journeys are found between the selected stops.
  ///
  /// In en, this message translates to:
  /// **'No direct scheduled journeys'**
  String get journeySearchNoDirectJourneysTitle;

  /// Empty state message when no direct scheduled journeys are found between the selected stops.
  ///
  /// In en, this message translates to:
  /// **'No direct scheduled buses were found between these stops in the current timetable.'**
  String get journeySearchNoDirectJourneysMessage;

  /// Notice indicating that all scheduled journeys for today have departed, but future scheduled journeys exist.
  ///
  /// In en, this message translates to:
  /// **'No more scheduled journeys for today'**
  String get journeySearchNoMoreJourneysToday;

  /// Heading for later scheduled journeys when no departures remain for today.
  ///
  /// In en, this message translates to:
  /// **'Next scheduled journeys'**
  String get journeySearchNextScheduledJourneys;

  /// Message displayed inside stop search when no stops match the search query.
  ///
  /// In en, this message translates to:
  /// **'No stops found'**
  String get journeySearchNoStopsFound;

  /// Duration display for zero-duration scheduled journeys.
  ///
  /// In en, this message translates to:
  /// **'Less than 1 min'**
  String get journeyDurationLessThanOneMinute;

  /// Duration in minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String journeyDurationMinutes(int minutes);

  /// Duration in whole hours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr'**
  String journeyDurationHours(int hours);

  /// Duration in hours and minutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr {minutes} min'**
  String journeyDurationHoursMinutes(int hours, int minutes);

  /// Route short name and destination/headsign text.
  ///
  /// In en, this message translates to:
  /// **'Route {shortName} · To {destination}'**
  String journeyTripRoute(String shortName, String destination);

  /// Route short name and long name fallback when headsign is empty.
  ///
  /// In en, this message translates to:
  /// **'Route {shortName} · {longName}'**
  String journeyTripRouteFallback(String shortName, String longName);

  /// Title displayed at the top of the Stops list screen.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get stopsTitle;

  /// Placeholder hint text in the stops search bar.
  ///
  /// In en, this message translates to:
  /// **'Search stops'**
  String get stopsSearchHint;

  /// Accessibility tooltip for the clear button in the stops search bar.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get stopsClearSearch;

  /// Message displayed when no stops match the active search query.
  ///
  /// In en, this message translates to:
  /// **'No stops found'**
  String get stopsNoStopsFound;

  /// Title displayed at the top of the Stop Details screen.
  ///
  /// In en, this message translates to:
  /// **'Stop details'**
  String get stopDetailsTitle;

  /// Title for the empty state when a requested stop cannot be found.
  ///
  /// In en, this message translates to:
  /// **'Stop not found'**
  String get stopNotFoundTitle;

  /// Message explaining that the requested stop was not found in the timetable.
  ///
  /// In en, this message translates to:
  /// **'This stop isn\'t in the current timetable.'**
  String get stopNotFoundMessage;

  /// Button label to return to Home from the stop-not-found state.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get stopNotFoundAction;

  /// Action button label to plan a journey starting from this stop.
  ///
  /// In en, this message translates to:
  /// **'Plan journey from here'**
  String get stopPlanJourneyFromHere;

  /// Heading for the section listing transit routes that serve this stop.
  ///
  /// In en, this message translates to:
  /// **'Routes serving this stop'**
  String get stopRoutesServingTitle;

  /// Message displayed when no routes serve a known stop.
  ///
  /// In en, this message translates to:
  /// **'No routes currently serve this stop'**
  String get stopNoRoutesServing;

  /// Heading for the upcoming departures section on the Stop Details screen.
  ///
  /// In en, this message translates to:
  /// **'Upcoming departures'**
  String get stopUpcomingDeparturesTitle;

  /// Title displayed at the top of the Routes list screen.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routesTitle;

  /// Empty state title displayed when the loaded timetable contains no routes.
  ///
  /// In en, this message translates to:
  /// **'No routes available'**
  String get routesNoRoutesAvailable;

  /// Title displayed at the top of the Route Details screen.
  ///
  /// In en, this message translates to:
  /// **'Route details'**
  String get routeDetailsTitle;

  /// Message displayed when a known route has zero scheduled trips or variants.
  ///
  /// In en, this message translates to:
  /// **'No scheduled trips available for this route.'**
  String get routeNoScheduledTrips;

  /// Heading for the ordered stop sequence section in Route Details.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get routeStopsHeading;

  /// Heading for the scheduled trips section in Route Details.
  ///
  /// In en, this message translates to:
  /// **'Scheduled trips'**
  String get routeScheduledTripsHeading;

  /// Header title for a route variant section.
  ///
  /// In en, this message translates to:
  /// **'Variant {index}: {origin} to {destination}'**
  String routeVariantTitle(int index, String origin, String destination);

  /// Accessibility label for an item in the ordered stop sequence.
  ///
  /// In en, this message translates to:
  /// **'Stop {position} of {total}: {stopName}'**
  String routeStopSequenceItemSemantics(
    int position,
    int total,
    String stopName,
  );

  /// Accessibility label for the first-stop departure time.
  ///
  /// In en, this message translates to:
  /// **'Departs {time}'**
  String routeDepartureEndpointSemantics(String time);

  /// Accessibility label for the final-stop arrival time.
  ///
  /// In en, this message translates to:
  /// **'Arrives {time}'**
  String routeArrivalEndpointSemantics(String time);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
