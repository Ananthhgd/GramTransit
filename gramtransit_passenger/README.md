# GramTransit Passenger App

The Passenger app provides bus timings and transit information for rural village routes.

**Status:** In development (Foundation phase).

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

- [Passenger Architecture v1.0](docs/architecture.md)
- [Development Guide](docs/development-guide.md)
- [Passenger ADRs](docs/adr/README.md)
