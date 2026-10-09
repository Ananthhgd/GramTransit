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
- Routes: named cleanly, paths are lowercase plurals (e.g., `/settings`)
- Providers: `camelCaseProvider`

## Testing Guidelines

- Prefer **fakes** (e.g., `InMemoryKeyValueStore`) over mock frameworks (no `mockito`/`mocktail`).
- Test only public Riverpod APIs. Do not test internal methods.
- Use test helpers from `test/helpers/` (like `pumpWidgetLocalised`) to avoid boilerplate.
- **Never blindly use `pumpAndSettle`** when indeterminate animations (`GtLoadingView`, `CircularProgressIndicator`) are present. Use `pump()` or `pump(Duration)`.

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
