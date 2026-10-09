# GramTransit Passenger Architecture v1.0

This document describes the Foundation architecture for the GramTransit Passenger app.

## Principles

- **Schedule-first**: The app must remain useful (providing timetables) when offline or when realtime data is unavailable. Realtime tracking is an enhancement, not the baseline.
- **Guest-first**: Public transit data must be accessible without requiring user login. Auth is only for personalized features (e.g. syncing favorites).
- **Accessibility/Multilingual**: Built with Material 3, focusing on contrast, touch targets, and localization. English is the default, with planned support for regional languages.
- **Lightweight Design**: Target devices are often low-end Android phones on weak rural networks.

## Layer Model

We use a feature-first folder structure with selective layering:
- `lib/core/`: Feature-agnostic infrastructure, design system, errors, and storage. It must NOT import `lib/app/` or `lib/features/`.
- `lib/features/<feature>/`: Feature-specific code. Each feature can contain `presentation`, `application`, and `domain`/`data` layers *only if useful*. No empty "future" folders.
- `lib/app/`: Composition root containing bootstrap logic and the application-wide router.

## Dependency Rules

- **Presentation** must not import concrete data implementations.
- **Feature isolation**: One feature must not import another feature's `data/` or `presentation/` internals.
- **Pure Domain**: Future `domain/` layers must not depend on Flutter framework packages (`package:flutter/`).

## Riverpod Rules

- Use **Riverpod 3** with manual provider syntax. No code generation.
- Use `Provider` for DI/sync dependencies (e.g., `keyValueStoreProvider`, `appConfigProvider`).
- Use `FutureProvider` for read-only async state.
- Use `NotifierProvider`/`AsyncNotifierProvider` for mutable state (e.g., `themeModeControllerProvider`).
- Avoid `BuildContext` inside Notifiers.

## Navigation

- Handled via **GoRouter** (`routerProvider`).
- Uses `StatefulShellRoute.indexedStack` for bottom navigation (Home / More).
- Routes are named and use lowercase plural paths (e.g. `/home`, `/settings`).
- No artificial waiting splash route.

## Environment/Config

- Environments (`dev`, `staging`, `prod`) are defined via `APP_ENV` dart-defines.
- Checked early during `bootstrap.dart` via `AppConfig.fromEnvironment()`.
- Parsed config is provided via `appConfigProvider`.

## Error Handling and Feedback

- Domain/Storage errors are modeled via `AppFailure` subtypes.
- `AsyncValueView` handles loading, data, and error states gracefully.
- Specific localized error messages are resolved via `AppFailureMessage`.

## Storage and Bootstrap

- **Storage**: Uses `SharedPreferencesWithCache` behind a `KeyValueStore` interface (`keyValueStoreProvider`).
- Storage is only for small settings (`gt.settings.theme_mode`). It must **NOT** be used as a large timetable/transit cache.
- `bootstrap.dart` handles pre-`runApp` initialization, safely falling back to an in-memory store if SharedPreferences fails.

## Logging

- Logging is centralized via `AppLogger` (`appLoggerProvider`).
- Sensitive data is not logged. No `debugPrint` in production.
