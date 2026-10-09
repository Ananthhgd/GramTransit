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

  /// Empty-state title shown inside the upcoming departures card.
  ///
  /// In en, this message translates to:
  /// **'No departures to show yet'**
  String get homeUpcomingDeparturesEmptyTitle;

  /// Empty-state explanatory message below the upcoming departures empty title.
  ///
  /// In en, this message translates to:
  /// **'Bus timetables will appear here once they are available.'**
  String get homeUpcomingDeparturesEmptyMessage;

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

  /// Title displayed on the route-not-found error screen.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get routeNotFoundTitle;

  /// Explanatory message on the route-not-found error screen.
  ///
  /// In en, this message translates to:
  /// **'The page you\'re looking for doesn\'t exist.'**
  String get routeNotFoundMessage;

  /// Button label on the route-not-found screen that navigates the user back to the Home screen.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
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
