# GramTransit Passenger Architecture

Version 1.2 — updated after Phase 2 (Direct Journey Discovery & Journey Search). Version 1.1 described Phase 1 (Transit Catalog & Offline Timetable); Version 1.0 described the Foundation baseline.

This document describes the implemented software architecture for the GramTransit Passenger application. It details structural layering, state management, data flow, transit scheduling logic, and engineering guardrails.

For historical rationale and decisions, see the [Passenger ADR Index](adr/README.md). For day-to-day engineering workflows and coding conventions, refer to the [Development Guide](development-guide.md).

---

## 1. Purpose and Status

The Passenger application provides rural village travelers with offline-capable bus timings, route listings, scheduled stop details, and direct point-to-point journey discovery.

- **Current Status:** Phase 1 (Transit Catalog & Offline Timetable) and Phase 2 (Direct Journey Discovery & Journey Search) are fully implemented. The application functions completely offline using an in-memory repository backed by an enriched bundled timetable snapshot (`sample-v2`).
- **Scope Boundary:** This document describes implemented, verified code. Future capabilities (such as realtime tracking, multi-leg transfers, remote synchronization, and account authentication) are documented strictly as planned items in [Section 17: Not Yet Implemented](#17-not-yet-implemented).

---

## 2. Product Principles

The application design is governed by four core product principles derived from system-level architecture (see [System ADR 0002](../../docs/adr/0002-schedule-first-and-guest-first.md)):

- **Schedule-first:** Baseline utility relies on scheduled transit timings that remain fully accessible when offline or when network connectivity is degraded. Realtime tracking is an optional enhancement for the future, never a baseline requirement.
- **Guest-first:** Public transit schedules are accessible without requiring sign-in or account registration. User authentication is reserved for future personalized synchronization (such as saved routes).
- **Accessible and Multilingual-ready:** Built with Material 3, focusing on touch targets (minimum 48×48 dp), high-contrast readability, 200% text scale support, and a non-color-dependent status system. English is currently active; Kannada and Malayalam domain structures are prepared.
- **Lightweight Design:** Tailored for entry-level Android smartphones operating in rural regions with low memory and weak intermittent network coverage. Heavy dependencies and unnecessary runtime abstractions are avoided.

---

## 3. Structure and Layering

The codebase employs a **feature-first** organization with **selective layering** (established in [ADR 0001](adr/0001-feature-first-selective-layering.md)):

```
lib/
├── app/                  # Composition root, bootstrap, and application-wide routing
├── core/                 # Feature-agnostic infrastructure, design system, errors, storage, time
└── features/             # Business feature modules
    ├── home/             # Home screen and scheduled upcoming departures UI
    ├── journey_search/   # Direct journey search presentation and widgets
    ├── more/             # Secondary navigation hub
    ├── settings/         # App settings (theme mode preference)
    ├── transit/          # Canonical transit domain, data repository, and shared providers
    └── trip_details/     # Trip details application view-model and presentation
```

### Layer Boundaries
- `lib/app/`: Composition root containing application bootstrap (`bootstrap.dart`), global widget shell, and the central GoRouter configuration (`lib/app/router/`).
- `lib/core/`: Feature-agnostic foundations. Contains design system tokens and feedback widgets (`core/design_system/`), error hierarchy (`core/error/`), localization and formatting helpers (`core/l10n/`), logging utilities (`core/logging/`), storage adapters (`core/storage/`), and time abstractions (`core/time/`).
- `lib/features/<feature>/`: Feature-specific logic. Layers exist only where warranted:
  - `domain/`: Pure Dart business entities, value objects, and repository contracts (e.g., `features/transit/domain/`).
  - `data/`: Data transfer objects, mappers, and concrete data sources (e.g., `features/transit/data/`).
  - `application/`: Presentation-facing projections, view-models, and state controllers (e.g., `features/trip_details/application/`).
  - `presentation/`: Widgets, screens, and display formatters (e.g., `features/journey_search/presentation/`).

### Canonical Transit Ownership
`lib/features/transit/` is the single canonical owner of transit models, timetable loading, and schedule logic. Consumer features (such as `home`, `journey_search`, and `trip_details`) consume models and providers from `transit`; they must never construct competing transit representations.

---

## 4. Dependency Rules

To prevent coupling and architectural erosion, five strict dependency rules are enforced:

1. **Presentation Layer Isolation:** `presentation/` code must never import concrete `data/` layer implementations. Presentation layers consume state via Riverpod providers or application view-models.
2. **Feature Encapsulation:** One feature must not import the private `data/` or `presentation/` internals of another feature. Cross-feature consumption occurs via public domain models, application view-models, or shared providers.
3. **Core Independence:** `lib/core/` must not import from `lib/app/` or `lib/features/`. Core is strictly a supplier to features and the composition root.
4. **Pure Domain:** `domain/` directories (e.g., `lib/features/transit/domain/`) must remain pure Dart and must not depend on Flutter (`package:flutter/`).
5. **Storage Adapter Isolation:** Third-party storage libraries (`package:shared_preferences`) may only be imported by the designated adapter (`lib/core/storage/shared_preferences_key_value_store.dart`) and bootstrap initialization.

These architectural invariants are validated on every CI run via native Dart guardrail tests in `test/architecture/import_rules_test.dart` (enforcing rules G1 through G7).

---

## 5. State Management

State management and dependency injection are implemented with **Riverpod 3** using manual provider syntax without code generation ([ADR 0002](adr/0002-riverpod-and-navigation.md)).

### Implemented Provider Inventory

| Provider Name | Type | Location | Purpose |
| :--- | :--- | :--- | :--- |
| `appConfigProvider` | `Provider<AppConfig>` | `core/config/` | Injected environment configuration (`dev`, `staging`, `prod`). |
| `appLoggerProvider` | `Provider<AppLogger>` | `core/logging/` | Application-wide centralized logging instance. |
| `keyValueStoreProvider` | `Provider<KeyValueStore>` | `core/storage/` | Key-value store abstraction backed by SharedPreferences. |
| `clockProvider` | `Provider<Clock>` | `core/time/` | Injected wall-clock abstraction (`SystemClock` in production). |
| `minuteTickerProvider` | `StreamProvider.autoDispose<DateTime>` | `core/time/` | Emits current time on wall-clock minute boundaries (`retry: null`). |
| `themeModeControllerProvider` | `NotifierProvider<ThemeModeController, ThemeMode>` | `features/settings/` | Manages theme mode state and persistence. |
| `timetableRepositoryProvider` | `Provider<TimetableRepository>` | `features/transit/` | Supplies the concrete `BundledTimetableRepository`. |
| `timetableProvider` | `FutureProvider<Timetable>` | `features/transit/` | Asynchronously loads and memoizes the timetable snapshot (`retry: null`). |
| `upcomingTripsProvider` | `Provider.autoDispose.family<AsyncValue<UpcomingTrips>, StopId>` | `features/transit/` | Synchronously joins timetable and minute ticker to evaluate upcoming departures. |
| `stopSearchProvider` | `Provider.autoDispose.family<AsyncValue<List<TransitStop>>, StopSearchQuery>` | `features/transit/` | Asynchronously searches stops against the loaded timetable with deterministic ranking. |
| `upcomingJourneysProvider` | `Provider.autoDispose.family<AsyncValue<UpcomingJourneys>, JourneyQuery>` | `features/transit/` | Synchronously joins timetable and minute ticker to evaluate direct upcoming scheduled journeys. |
| `tripDetailsProvider` | `Provider.autoDispose.family<AsyncValue<TripDetails?>, TripId>` | `features/trip_details/` | Projects timetable data into an immutable `TripDetails` application view-model. |
| `routerProvider` | `Provider<GoRouter>` | `app/router/` | Central declarative routing configuration. |

### Operational Rules
- `FutureProvider` and `StreamProvider` definitions that handle local or periodic state explicitly set `retry: (_, _) => null` to prevent automatic, uncoordinated background retry loops.
- Asynchronous data refresh is triggered explicitly via user-driven UI actions using `ref.refresh(...)`.
- Direct journey search and stop search use pure domain functions (`findUpcomingJourneys`, `searchStops`) paired with parameter-keyed providers (`JourneyQuery`, `StopSearchQuery`). No stateful Riverpod controller is introduced for Journey Search.

---

## 6. Navigation

Navigation is managed declaratively via **GoRouter** (`lib/app/router/app_router.dart`) using named routes defined in `lib/app/router/app_routes.dart`.

### Route Map

```
Root Navigator (_rootNavigatorKey)
├── StatefulShellRoute.indexedStack (AppShell with BottomNavigationBar)
│   ├── Branch 0: /home (name: "home") -> HomeScreen
│   └── Branch 1: /more (name: "more") -> MoreScreen
│       └── /more/settings (name: "settings") -> SettingsScreen
├── /trips/:tripId (name: "tripDetails") -> TripDetailsScreen
└── /journeys (name: "journeys") -> JourneySearchScreen
```

### Navigation Characteristics
- **Persistent Shell State:** Bottom navigation tabs (Home and More) are mounted in a `StatefulShellRoute.indexedStack`. Switching tabs preserves scroll positions and private widget state.
- **Top-Level Detail and Search Navigation:** Both Trip Details (`/trips/:tripId`) and Journey Search (`/journeys`) are registered on the root navigator (`_rootNavigatorKey`). They overlay the bottom navigation bar to provide a focused, full-screen task interface. Navigating back returns directly to the preserved Home screen state.
- **Two-Stage Route & Query Validation:** The `/journeys` route accepts optional `from` and `to` query parameters (`/journeys?from=<StopId>&to=<StopId>`):
  - *Stage 1 (Router Syntactic Validation):* `parseQueryStopId` converts non-empty trimmed strings into `StopId` or `null`. The router performs no asynchronous timetable lookups, redirects, or assertions.
  - *Stage 2 (Screen Semantic Sanitization):* `JourneySearchScreen` validates parsed IDs against the loaded timetable upon the first successful timetable load (`_didSanitizeInitialQuery`). Unknown stops are cleared to `null`, identical From and To values retain From and clear To, and valid distinct stops are retained. This validation happens silently without mutating the URL.
- **Home to Journey Search Navigation:** Tapping the search entry placeholder on Home navigates to `/journeys?from=<StopId>` if a boarding stop is currently selected, or to `/journeys` if unselected. Only primitive `StopId` values cross the route boundary. Back navigation returns to the preserved Home screen state.
- **No Artificial Splash Route:** The application loads immediately into the Home tab. Async initialization and data fetching display contextual loading indicators rather than blocking the user with an artificial splash screen.

---

## 7. Transit Model and Timetable

The transit catalog and timetable domain are specified in [ADR 0005](adr/0005-offline-timetable-and-transit-model.md) and [ADR 0006](adr/0006-direct-journey-discovery-and-journey-search.md), and implemented under `lib/features/transit/`.

### Canonical Domain Model

| Entity / Value Object | Responsibility | Key Invariants |
| :--- | :--- | :--- |
| `StopId`, `RouteId`, `TripId` | Strongly typed identifiers | Non-empty trimmed string values. |
| `LocalizedText` | Multilingual string holder | Non-empty English; optional Kannada and Malayalam. |
| `ServiceTime` | Service-day clock time | Hours `00`–`47`, minutes `00`–`59`. Supports late-night service day association. |
| `ServiceDays` | Day-of-week operating schedule | Boolean flags for Monday through Sunday. Date matching via `operatesOn(DateTime)`. |
| `TransitStop` | Physical or named bus stop | Unique `StopId` and `LocalizedText` name. |
| `TransitRoute` | Transit route definition | Unique `RouteId`, short name, and long name. |
| `StopTime` | Scheduled stop arrival and departure | Non-null `arrivalTime` and `departureTime`; departure >= arrival. |
| `ScheduledTrip` | Route trip run and stop sequence | Unmodifiable `List<StopTime>`; sequential ordering (`departure[i] <= arrival[i+1]`). |
| `Timetable` | Complete transit catalog snapshot | Unmodifiable lists of stops, routes, and trips; validated relational references. |
| `TimetableInfo` | Snapshot metadata | Validated `datasetVersion` string and `isSampleData` boolean flag. |
| `ScheduledJourney` | Scheduled direct journey occurrence | Boarding stop, downstream alighting stop, scheduled departure, and arrival times. `boardingStopId != alightingStopId`; `scheduledArrival >= scheduledDeparture`. |
| `UpcomingJourneys` | Direct journey query result set | Immutable grouped results containing `current` and `nextLater` lists for a queried stop pair. |

### Derived Projections
- **`TripOccurrence`:** Projections of a `ScheduledTrip` for a queried stop, pairing scheduled stop departure and destination arrival with an absolute calendar `DateTime`. Destination stop name is derived from the final stop time in the trip's sequence. Direction is not a domain entity attribute.
- **`UpcomingTrips`:** The grouped result set for a stop containing `current` and `nextLater` departure lists.
- **`TripDetails` & `TripStopRow`:** Application view-models projecting trip information into an ordered stop list with classified positions (`first`, `intermediate`, `last`).
- **`ScheduledJourney` & `UpcomingJourneys`:** Canonical domain models representing point-to-point direct journey runs between two distinct stops on the same scheduled trip.

### Direct Journey Eligibility and Discovery
A scheduled trip represents an eligible direct journey from `boardingStopId` to `alightingStopId` when the alighting stop appears strictly after the boarding stop in the trip's scheduled stop sequence (`alightingIndex > boardingIndex`).

Key domain rules:
- **Sequence-Based Eligibility:** Eligibility is based on stop sequence position, not clock-time strictness. Same-time arrival and departure (`scheduledArrival >= scheduledDeparture`) is valid; zero-duration journeys (`Duration.zero`) are permitted by the domain model and displayed in presentation as `"Less than 1 min"`.
- **Shared Candidate Evaluation:** `findUpcomingJourneys` shares candidate evaluation logic with `findUpcomingTrips` via the pure domain helper `_evaluateBoardingCandidates`:
  - Matches operating days (`trip.serviceDays.operatesOn(...)`).
  - Supports late-night service hours (`00` to `47`) mapped to service dates.
  - Excludes departures already passed relative to the query minute.
  - Excludes boarding at a trip's terminating stop.
  - Evaluates yesterday and today (offsets `-1` and `0`) for immediate `current` departures.
  - Evaluates the subsequent 7 service dates (offsets `+1` to `+7`) for `nextLater` departures if and only if `current` has no eligible journeys.
- **Direct Journeys Only:** Phase 2 supports single-vehicle direct journeys only. Transfers and connection routing are excluded.

### Stop Search and Ranking
Offline stop search is implemented in `lib/features/transit/domain/stop_search.dart` as pure function `searchStops`:
- Operates entirely offline against in-memory `Timetable.stops`.
- Normalization via `normalizeStopSearch`: converts text to lowercase; deletes `.`, `'`, and `’`; replaces `-`, `–`, `/`, `,`, `(`, and `)` with spaces; trims and collapses repeated whitespace.
- Deterministic ranking into four buckets when query is non-empty:
  1. Exact normalized match.
  2. Normalized name starts with normalized query.
  3. Any word in normalized name starts with normalized query.
  4. Other substring match.
- Ties within buckets and empty queries preserve original timetable order.
- Accepts an optional `excludedStopId` parameter to filter out the boarding stop from destination results.
- Duplicate stop names (physical stops sharing identical names) remain distinct entities identified by unique `StopId`.
- Phase 2 scope is English stop search; transliteration and regional script matching are deferred.

### Bundled Snapshot and Validation
- Timetable data is packaged as a local asset at `assets/transit/timetable.json`.
- In Phase 2, the asset is enriched to `datasetVersion: "sample-v2"`, schema version `1`, `isSampleData: true`, adding rural stop networks and multi-route overlaps to support journey search verification.
- Deserialization in `TimetableDto` and mapping in `TimetableMapper` enforce **fail-closed validation**. Missing properties, duplicate keys, unreferenced identifiers, negative run times, or unsupported schema versions throw `TimetableFormatException`, which the repository maps to `DataFormatFailure`.

---

## 8. Time Handling

Schedule logic requires strict determinism and isolation from ambient system clocks.

### Abstractions and Invariants
- **Clock Abstraction:** The `Clock` interface (`lib/core/time/clock.dart`) encapsulates current time reads. Production code uses `SystemClock`, which delegates to `DateTime.now()`.
- **Deterministic Testing:** In unit and widget tests, `clockProvider` is overridden with fixed or scripted fakes to simulate arbitrary times without thread sleeps.
- **Minute-Aligned Updates:** `minuteTickerProvider` calculates the exact millisecond duration to the next wall-clock minute boundary and emits ticks, triggering synchronized UI refreshes.
- **Device-Local Time Zone:** `SystemClock` uses device-local `DateTime` behavior, and `ServiceTime.toDateTime` constructs local `DateTime` instances. The application operates in the device's local time zone; it does not configure or enforce Indian Standard Time (IST).

---

## 9. Home: Scheduled Departures

The Home screen (`lib/features/home/presentation/home_screen.dart`) presents scheduled bus departures from rural stops and acts as the entry point for Journey Search.

### User Interaction and State Ownership (Model H-A)
- **State Ownership:** `HomeScreen` owns the session-local `StopId? _selectedStopId` in `_HomeScreenState`.
- **Controlled Section:** `UpcomingDeparturesSection` is a controlled presentation widget receiving `selectedStopId` and emitting `onStopSelected`.
- **No Riverpod Home Controller:** Stop selection is ephemeral UI state; it is not managed in Riverpod or persisted across app restarts.
- **State Preservation:** Navigating to Journey Search or the More tab and returning preserves Home's `_selectedStopId` via GoRouter's navigation stack.
- **Search Entry Navigation:** Tapping the search entry placeholder invokes `_onSearchTapped`:
  - If a stop is selected: navigates to `/journeys?from=<StopId>`.
  - If no stop is selected: navigates to `/journeys`.
  - Only primitive `StopId` values cross the route boundary.
- **Schedule Departure Grouping:**
  - `current`: Departures occurring on the current or previous operating day whose scheduled departure is >= the query minute.
  - `nextLater`: If `current` has no departures, `nextLater` searches up to seven subsequent calendar days to display the next scheduled service.
- **Disclosures and Notices:**
  - Persistent disclosure: `"Scheduled times. Actual times may vary."` (`ScheduledTimesNote`).
  - Sample data banner: If `timetable.info.isSampleData` is true, an explicit notice (`SampleDataNotice`) is displayed stating the data is for testing and not for real travel.

---

## 10. Trip Details

The Trip Details screen (`lib/features/trip_details/presentation/trip_details_screen.dart`) provides a full, date-independent view of a scheduled trip.

### Display Rules
- **Header:** Displays route short name, long name, derived origin-to-destination stops, and formatted operating days (e.g., `"Runs every day"` or `"Runs Mon, Tue, Wed"`).
- **Stop Sequence:** Rendered as an ordered timeline (`TripStopList`):
  - *First stop:* Displays scheduled departure time only.
  - *Last stop:* Displays scheduled arrival time only.
  - *Intermediate stops (equal times):* Displays a single clock time.
  - *Intermediate stops (differing times):* Displays separate arrival and departure times.
- **After-Midnight Times:** Times with hour >= 24 are normalized to 12-hour or 24-hour clock displays with a `+1` badge and `"next day"` screen-reader accessibility semantics.
- **Missing or Invalid Trips:** If a `TripId` is unparseable or does not exist in the timetable, the screen displays a `GtEmptyState` with an action navigating back to Home.

---

## 11. Journey Search

The Journey Search feature (`lib/features/journey_search/presentation/`) provides point-to-point scheduled journey discovery between a selected boarding stop and an alighting stop.

### User Interaction and Presentation Architecture
- **Screen & Local State:** `JourneySearchScreen` manages local `_boardingStopId` and `_alightingStopId` widget state.
- **Stop Selection:** Dual `JourneyStopSelector` widgets wrap Material 3 `SearchAnchor` for responsive, searchable stop selection. The destination selector sets `excludedStopId: effectiveFrom` to prevent picking the same stop.
- **Stop Swap Semantics:** An icon button allows rapid origin/destination swapping:
  - Both selected: swaps From and To.
  - From only: previous From becomes To; From is cleared.
  - To only: previous To becomes From; To is cleared.
  - Neither selected: no-op.
  - Selecting From identical to To automatically clears To.
- **Reactive Results:** `JourneyResultsSection` observes `upcomingJourneysProvider` automatically when both distinct stops are chosen. No manual "Search" button is required; results update reactively on stop selection, minute ticks, or timetable reload.
- **Result States:**
  - *Guidance State:* Displays a prompt card asking the passenger to choose starting and destination stops when either is unselected.
  - *Loading State:* Renders `GtLoadingView` during query processing.
  - *Error State:* Displays `GtErrorView` with a retry callback refreshing the provider.
  - *Current Results:* Displays `ScheduledJourneyCard` items for journeys departing today.
  - *Next-Later Results:* When no more journeys run today, displays an informational notice followed by scheduled journeys on subsequent service dates (with departure date badges).
  - *Empty State:* Displays a localized empty message when no direct journeys exist across the 7-day search window.
- **Duration and Date Formatting:** Scoped helpers in `journey_display_format.dart`:
  - `Duration.zero` renders explicitly as `"Less than 1 min"`.
  - Non-zero durations format as minutes, hours, or hours and minutes.
  - Clock times respect 12/24-hour system preferences; next-day arrivals display `+1` badges.
- **Disclosures and Notices:**
  - Persistent schedule disclosure note (`JourneyScheduledTimesNote`): `"Scheduled times. Actual times may vary."`
  - Sample data banner (`JourneySampleDataNotice`): shown when `timetable.info.isSampleData` is true.

---

## 12. Errors and Async State

Error presentation is strongly typed and centralized to maintain fail-safe behavior.

### Failure Hierarchy
Implemented under `lib/core/error/app_failure.dart`:
- `StorageFailure`: Failure reading or writing persistent device storage.
- `DataFormatFailure`: Malformed or unparseable timetable JSON or missing relational data.
- `UnexpectedFailure`: Unhandled fallback wrapper.

### Presentation Mapping
- `AppFailureMessage.of(failure, l10n)` exhaustively maps failures to localized strings (`l10n.errorDataFormat`, `l10n.errorStorage`, `l10n.errorUnexpected`).
- `AsyncValueView<T>` handles `AsyncValue` state mapping. It is configured with `skipLoadingOnRefresh: true` and `skipLoadingOnReload: true` so that previously loaded timetable data remains visible during asynchronous refreshes to avoid visual flickering.

---

## 13. Configuration, Bootstrap and Storage

### Bootstrap Sequence
Executed in `lib/app/bootstrap.dart` before `runApp()`:
1. Ensures widget binding is initialized.
2. Parses environment configuration from `--dart-define=APP_ENV` via `AppConfig.fromEnvironment()`.
3. Initializes `SharedPreferencesWithCache`. If platform storage fails, it falls back safely to an in-memory storage implementation (`InMemoryKeyValueStore`), ensuring the application can always launch.
4. Initializes application logging.

### Storage Boundary
The storage abstraction (`KeyValueStore`) is strictly limited to key-value user preferences (e.g., `gt.settings.theme_mode`). It is **never** used to cache or store transit timetable data ([ADR 0003](adr/0003-environment-bootstrap-and-lightweight-storage.md)).

---

## 14. Logging

Logging is centralized via `AppLogger` (`lib/core/logging/app_logger.dart`):
- Provides leveled logging: `debug`, `info`, `warning`, `error`.
- In production builds, log output avoids dumping sensitive personal data.
- Raw Flutter `debugPrint` calls in production code are strictly forbidden and guarded by architecture test `G7`.

---

## 15. Design System, Accessibility and Localization

### Design System Tokens and Components
Implemented under `lib/core/design_system/`:
- **Tokens:** Spacing (`GtSpacing`), corner radii (`GtRadius`), color palettes (`GtColors`), and typography scales (`GtTypography`).
- **Feedback Components:** Consistent loading indicators (`GtLoadingView`), localized error banners with retry triggers (`GtErrorView`), and empty state layouts (`GtEmptyState`).

### Accessibility Invariants
- Minimum touch targets of 48×48 dp for interactive controls.
- Text layouts support up to 200% system font scaling without clipping.
- Timeline indicators and decorative icons are excluded from screen-reader semantics (`ExcludeSemantics`), while stop times provide descriptive semantic labels.
- Information is never conveyed through color alone.

### Localization Strategy
- **UI Strings:** All static UI text is localized through Flutter ARB files (`lib/core/l10n/arb/`) generating `AppLocalizations`.
- **Transit Proper Names:** Stop and route names use `LocalizedText` (resolving currently to English, ready for regional language expansion).
- **Date/Time Formatting:** Feature layers use shared helpers in `lib/core/l10n/date_time_formatting.dart` to respect system 12/24-hour preferences and locale calendars.

---

## 16. Testing Approach

Testing emphasizes speed, determinism, and architectural integrity without brittle mock libraries ([ADR 0004](adr/0004-testing-ci-and-architecture-guardrails.md)).

### Test Strategy
- **Fakes over Mocks:** No mockito or mocktail. Tests use focused in-memory fakes (e.g., `InMemoryKeyValueStore`, `FakeAssetBundle`, fixed `Clock`).
- **Public API Verification:** Tests exercise public provider and domain interfaces.
- **Deterministic Time:** Tests override `clockProvider` or `minuteTickerProvider` with controlled instances.
- **Architecture Guardrails:** Zero-dependency static analyzer tests in `test/architecture/import_rules_test.dart` enforce layer boundaries, forbidden dependencies, and clean domain isolation.
- **Shipped Asset Verification:** `test/features/transit/data/bundled_timetable_asset_test.dart` verifies that the actual bundled asset loads and validates against the real repository implementation.

---

## 17. Not Yet Implemented

The following features are planned for future phases and are not part of the Phase 1 or Phase 2 architecture:

- **Transfers & Multi-Leg Journey Planning:** Routing across multiple bus routes with connection transfers and interchange buffers (Phase 2 is direct journeys only).
- **Multilingual / Regional Stop Search:** Stop search matching Kannada and Malayalam scripts or phonetic transliteration (Phase 2 is English stop search).
- **Remote Timetable Source & Caching:** Downloading updated timetable snapshots over HTTPS with SQLite or local filesystem caching.
- **Backend API Integration:** Connecting to Spring Boot backend services.
- **Realtime Vehicle Tracking:** Live bus positions, arrival delay calculations, and WebSocket streaming.
- **GPS and Interactive Maps:** Device geolocation, nearby stop auto-selection, and route map rendering.
- **Authentication & Cloud Sync:** Guest account conversion and cross-device favorites synchronization.
- **Push Notifications:** Service disruption alerts and departure reminders.
- **Multilingual UI Expansion:** Full user interface translations for Kannada and Malayalam.
- **Persisted User Selections:** Persisting recently selected stops or favorite village routes across sessions.
