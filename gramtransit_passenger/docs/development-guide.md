# GramTransit Passenger Development Guide

## Setup and Verification

Always run local verification before submitting changes:
```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter test test/core/config/app_config_dart_define_test.dart --dart-define=APP_ENV=prod --dart-define=EXPECTED_APP_ENV=prod
```

## Naming Conventions

- Files/folders: `snake_case`
- Routes: named cleanly, paths are lowercase plurals or parameterized paths (e.g., `/more/settings`, `/trips/:tripId`)
- Providers: `camelCaseProvider`

## Testing Guidelines

- Prefer **fakes** (e.g., `InMemoryKeyValueStore`, `FakeAssetBundle`) over mock frameworks (no `mockito`/`mocktail`).
- Test only public Riverpod APIs. Do not test internal methods.
- Use test helpers from `test/helpers/` (like `pumpWidgetLocalised`) to avoid boilerplate.
- **Never blindly use `pumpAndSettle`** when indeterminate animations (`GtLoadingView`, `CircularProgressIndicator`) are present. Use `pump()` or `pump(Duration)`.

## Working with the Bundled Timetable

- **Asset Path:** Shipped timetable data lives at `assets/transit/timetable.json`.
- **Top-Level Metadata:** Contains `schemaVersion` (must be 1), `datasetVersion` (string identifier), and `isSampleData` (boolean).
- **Fail-Closed Validation:** The dataset is validated all-or-nothing during load. Missing properties, duplicate IDs, missing references, or invalid times throw `TimetableFormatException`, which maps to `DataFormatFailure`. The app never partially renders corrupt data.
- **Sample Data Flag:** When `isSampleData` is `true`, the Home screen displays an explicit testing banner. Production datasets will set this flag to `false`.
- **Late-Night Times (>= 24:00):** Service times accept hours `00` through `47`. A time of `24:15` denotes 15 minutes past midnight on the *previous operating day's service*. The UI formats these as normalized clock times with a `+1` next-day badge.
- **Shipped Asset Verification:** Any modification to `timetable.json` must pass `test/features/transit/data/bundled_timetable_asset_test.dart` to verify that the file parses through the real repository.

## Time in Code

- **Injected Time:** Always read time through the injected `Clock` (`clockProvider`) or the `minuteTickerProvider`.
- **No Uncontrolled Reads:** Never call `DateTime.now()` directly inside domain entities, repositories, or scheduling logic.
- **Testing Time:** Override `clockProvider` or `minuteTickerProvider` in tests using a fixed `Clock` or deterministic stream to simulate specific service dates and times without sleeps.
- **Time Zone Behavior:** `SystemClock` uses device-local time, and `ServiceTime.toDateTime` constructs local `DateTime` instances. Code operates in the device's local time zone; do not assume or enforce Indian Standard Time (IST) in code.

## Using the Transit Model

- **Canonical Entities:** Always consume domain models (`TransitStop`, `TransitRoute`, `ScheduledTrip`, `Timetable`, `ScheduledJourney`, `UpcomingJourneys`, `RouteVariant`) from `lib/features/transit/domain/` and shared providers (`timetableProvider`, `upcomingTripsProvider`, `stopSearchProvider`, `upcomingJourneysProvider`, `stopDetailsProvider`, `routeDetailsProvider`).
- **No Competing Models:** Never create feature-local classes representing stops, routes, trips, scheduled journeys, or route variants.
- **Domain Logic Placement:** Calculation of boardable departures, direct journey discovery, stop search, and route catalog projections belong in pure domain functions (`findUpcomingTrips`, `findUpcomingJourneys` in `upcoming_trips_logic.dart`, `searchStops` in `stop_search.dart`, and `routeVariants`, `routesServingStop` in `route_catalog.dart`), never inside UI widget trees or controllers. Never perform timetable parsing, candidate filtering, or trip sequencing in UI widgets.
- **Provider Queries:** When reading `stopSearchProvider` or `upcomingJourneysProvider`, always pass immutable parameter keys (`StopSearchQuery` and `JourneyQuery`). When reading `stopDetailsProvider` or `routeDetailsProvider`, pass typed domain identifiers (`StopId`, `RouteId`).

## Working with Journey Search

- **Feature Location:** Journey Search presentation code lives in `lib/features/journey_search/presentation/` (`journey_search_screen.dart`, `widgets/`).
- **No Feature-Level Riverpod Controller:** Journey Search does not have a Riverpod view-model or state controller. Local From/To selection is managed as widget state within `_JourneySearchScreenState`, while results are derived reactively from `upcomingJourneysProvider`.
- **Home State Ownership (Model H-A):** `HomeScreen` owns session-local `_selectedStopId` and passes it to `UpcomingDeparturesSection` via parameters. Tapping the search entry passes `from=<StopId>` via query parameters. Home selection is not stored in a global Riverpod provider and is not persisted across app restarts.
- **Two-Stage Route & Query Initialization:**
  - *Stage 1 (Router level):* `parseQueryStopId` in `lib/app/router/app_router.dart` syntactically validates `from` and `to` query parameters, returning a `StopId` or `null`. The router never accesses the timetable, throws exceptions, or redirects based on data validity.
  - *Stage 2 (Screen level):* `JourneySearchScreen` performs a one-time semantic sanitization against the loaded timetable (`_didSanitizeInitialQuery`). Unknown stops are cleared to `null`; identical From and To values retain From and clear To. This sanitization is silent and does not mutate the route URL.
- **Journey Duration Formatting:** Zero-duration journeys (`Duration.zero`) must be formatted using `formatJourneyDuration` as `"Less than 1 min"`.

## Working with Stops and Routes Browsing

- **Feature Location:** Stops and routes browsing code lives in `lib/features/browse/` (`application/` and `presentation/` only). Catalog derivations (`routeVariants`, `routesServingStop`) reside in `lib/features/transit/domain/route_catalog.dart`.
- **Route Patterns & Invariants:** `TransitRoute` holds metadata only. Operating stop patterns are derived dynamically as `RouteVariant`. Every variant requires at least 2 stops, at least one trip, matching `routeId`, and identical stop sequences across trips.
- **Application Providers:** `stopDetailsProvider(stopId)` and `routeDetailsProvider(routeId)` watch `timetableProvider`. If the ID exists, they resolve `AsyncData(details)`. If the ID does not exist, they resolve `AsyncData(null)`.
- **Router-Agnostic Presentation:** `StopsScreen`, `StopDetailsScreen`, `RoutesScreen`, and `RouteDetailsScreen` are pure presentation components that expose callbacks (`onStopTap`, `onPlanJourney`, `onTripTap`, `onBack`, `onRouteTap`). They never invoke `GoRouter` or inspect route parameters directly.
- **Two-Stage Path Parameter Validation:**
  - *Stage 1 (Router level):* `parsePathStopId` and `parsePathRouteId` in `app_router.dart` syntactically parse parameters using domain constructors (`try/on ArgumentError`). Malformed parameters return `null` and render a router-level not-found `GtEmptyState`.
  - *Stage 2 (Screen level):* Syntactically valid but unknown IDs resolve to `AsyncData(null)` in the provider, rendering the screen-level `GtEmptyState` not-found view with back navigation.
- **Trip Row Endpoint Time Semantics:** First-stop departure and last-stop arrival times are evaluated independently via `formatServiceTime`. Hours >= 24 normalize to clock times with a `+1` next-day marker. Screen-reader semantics announce departure/arrival and next-day meaning independently. Never infer next-day status at row level.
- **Shared Weekday Formatting:** Decoupled helpers `formatShortWeekday` and `formatShortWeekdays` in `lib/core/l10n/date_time_formatting.dart` accept integer weekday constants (`DateTime.monday` through `DateTime.sunday`). Do not import `ServiceDays` into `core/`.
- **Browse Disclosures:** Use `BrowseSampleDataNotice` (compact in lists, standard in details; suppressed in loading/error/not-found) and `BrowseScheduledTimesNote` on schedule lists.

## Scheduled-Information Copy

- **Schedule Disclosure:** Any screen displaying departure, arrival, or journey times must include the persistent disclosure: `"Scheduled times. Actual times may vary."` (`ScheduledTimesNote`, `TripScheduledTimesNote`, `JourneyScheduledTimesNote`, or `BrowseScheduledTimesNote`).
- **No Realtime Implications:** Contributors must never write UI copy that falsely implies live vehicle tracking, punctuality, or current delays. Avoid words like *"live"*, *"arriving in 5 mins"*, *"delayed"*, or *"on time"*. Phase 1, Phase 2, and Phase 3 display scheduled timings only.

## Proper Names and Formatting

- **Transit Names:** Stop names and route names must be encapsulated in `LocalizedText`. In Phase 1, Phase 2, and Phase 3, UI resolves `LocalizedText.english`.
- **UI Strings:** All static UI text must come from `AppLocalizations` via ARB files (`lib/core/l10n/arb/app_en.arb`).
- **Date and Time Formatting:** Use the shared helpers in `lib/core/l10n/date_time_formatting.dart` (`formatClockTime`, `formatShortDate`, `formatShortWeekday`, `formatShortWeekdays`) to respect system 12/24-hour preferences and locale formats. For journey cards, use `journey_display_format.dart`; for browse cards, use `browse_display_format.dart`.

## Feature-Local Test Support

- When writing feature-level tests, place test fixtures and harness helpers in `test/features/<feature>/<feature>_test_support.dart` (for example, `home_test_support.dart`, `trip_details_test_support.dart`, or `browse_test_support.dart`).
- Keep shared fakes in `test/helpers/fakes/` and widget helpers in `test/helpers/widget_pump_helper.dart`. Do not invent alternative test-support structures.
- **Targeted Test Suites:** Run targeted test suites during feature development:
  ```bash
  # Journey search
  flutter test test/features/journey_search/
  flutter test test/app/journey_search_navigation_test.dart
  flutter test test/features/transit/domain/upcoming_journeys_logic_test.dart
  flutter test test/features/transit/domain/stop_search_test.dart
  flutter test test/features/transit/providers/journey_search_providers_test.dart

  # Stops and routes browsing
  flutter test test/features/browse/
  flutter test test/app/browse_navigation_test.dart
  flutter test test/features/transit/domain/route_catalog_test.dart
  flutter test test/features/browse/application/browse_providers_test.dart
  ```

## General Rules

- **UI Strings**: Must come from localization (`AppLocalizations`). Do not hardcode strings in the UI.
- **Generated Files**: `lib/core/l10n/generated/` is committed to the repository. Run `flutter gen-l10n` to update it.
- **Line Endings**: Repository enforces LF. See `.gitattributes`.
- **No `debugPrint`**: Remove print statements in production code. Use `AppLogger` instead.
- **Flutter Upgrades**: Do not blindly upgrade Flutter without explicit architecture approval. We pin exactly `3.47.6` in CI.

## Coding Agent Rules

If you are an AI assistant working on this repository:
- No platform changes (Android/iOS) without explicit architecture approval.
- No dependency additions without explicit approval.
- No Flutter upgrades.
- Do not suppress lints (e.g. `// ignore:`) to hide problems. Fix the root cause.
- Stop and report any architecture violations immediately.
- Inspect and read back changes before claiming success.
