# GramTransit Passenger App

The Passenger app provides bus timings and transit information for rural village routes.

**Status:** In development (Phase 3 — Stops, Routes & Timetable Browsing complete; Phase 2 — Direct Journey Discovery & Journey Search complete; Phase 1 — Transit Catalog & Offline Timetable complete).

## Implemented Capabilities

- **Offline Scheduled Departures:** View upcoming bus departures from a selected boarding stop evaluated against bundled timetable data.
- **Direct Journey Discovery:** Search scheduled direct journeys between boarding (`From`) and destination (`To`) stops without requiring live connectivity.
- **Offline Stop Search:** Fast, deterministic English stop search with instant filtering and ranking.
- **Stops Browsing & Stop Details:** Browse all stops in the network, search stops offline, inspect serving routes and upcoming departures, and launch journey planning directly from a stop (`/stops`, `/stops/:stopId`).
- **Routes Browsing & Route Details:** Browse all operated routes, inspect derived route-pattern variants with complete ordered stop sequences, and view scheduled trips with operating days (`/routes`, `/routes/:routeId`).
- **Home Explore Navigation:** Direct home-screen entry points to explore all stops and all routes without mutating session boarding selections.
- **Top-Level Journey and Catalog Routing:** Dedicated `/journeys`, `/stops`, `/stops/:stopId`, `/routes`, and `/routes/:routeId` screens supporting direct deep linking and resilient two-stage parameter validation.
- **Schedule-First & Guest-First:** Complete offline functionality with bundled sample timetable data (`sample-v2`). No user login, no backend API, and no GPS/maps required.
- **Scheduled Information Only:** Displays scheduled timetable timings; does not provide live vehicle positions, real-time delays, or multi-leg transfers.

## Prerequisites

- **Flutter**: 3.47.6 (stable)
- **Dart**: 3.13.5
- **Android**: Primary development target

## Setup & Run

1. Fetch dependencies:
   ```bash
   flutter pub get
   ```
2. Generate localization files:
   ```bash
   flutter gen-l10n
   ```
3. Run the app locally (defaulting to the `dev` environment):
   ```bash
   flutter run
   ```
   *Note: To run a specific environment, use `--dart-define=APP_ENV=prod` or `--dart-define=APP_ENV=staging`.*

## Local Verification

Run these commands before submitting changes:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter test test/core/config/app_config_dart_define_test.dart --dart-define=APP_ENV=prod --dart-define=EXPECTED_APP_ENV=prod
```

## Documentation

- [Passenger Architecture](docs/architecture.md)
- [Development Guide](docs/development-guide.md)
- [Passenger ADRs](docs/adr/README.md)
