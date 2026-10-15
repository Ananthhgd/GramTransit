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

- **Canonical Entities:** Always consume domain models (`TransitStop`, `TransitRoute`, `ScheduledTrip`, `Timetable`) from `lib/features/transit/domain/` and providers from `lib/features/transit/providers/`.
- **No Competing Models:** Never create feature-local classes representing stops, routes, or trips.
- **Domain Logic Placement:** Calculation of boardable departures, service-day matching, and terminal-stop filtering belong in pure domain functions (`findUpcomingTrips` in `upcoming_trips_logic.dart`), never inside UI widget trees or controllers.

## Scheduled-Information Copy

- **Schedule Disclosure:** Any screen displaying departure or arrival times must include the persistent disclosure: `"Scheduled times. Actual times may vary."` (`ScheduledTimesNote` or `TripScheduledTimesNote`).
- **No Realtime Implications:** Contributors must never write UI copy that falsely implies live vehicle tracking, punctuality, or current delays. Avoid words like *"live"*, *"arriving in 5 mins"*, *"delayed"*, or *"on time"*. Phase 1 displays scheduled timings only.

## Proper Names and Formatting

- **Transit Names:** Stop names and route names must be encapsulated in `LocalizedText`. In Phase 1, UI resolves `LocalizedText.english`.
- **UI Strings:** All static UI text must come from `AppLocalizations` via ARB files (`lib/core/l10n/arb/app_en.arb`).
- **Date and Time Formatting:** Use the shared helpers in `lib/core/l10n/date_time_formatting.dart` (`formatClockTime`, `formatShortDate`, `formatShortWeekday`) to respect system 12/24-hour preferences and locale formats.

## Feature-Local Test Support

- When writing feature-level tests, place test fixtures and harness helpers in `test/features/<feature>/<feature>_test_support.dart` (for example, `home_test_support.dart` or `trip_details_test_support.dart`).
- Keep shared fakes in `test/helpers/fakes/` and widget helpers in `test/helpers/widget_pump_helper.dart`. Do not invent alternative test-support structures.

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
