# 0003: Environment Bootstrap and Lightweight Storage

**Status:** Accepted
**Date:** 2026-10-09

## Context

The app needs environment-specific configuration and local persistence for small settings (like theme preference).

## Decision

- Use `--dart-define=APP_ENV=<env>` for environment strategy (`dev`, `staging`, `prod`).
- `bootstrap.dart` handles pre-`runApp` initialization, parsing the environment and setting up dependencies.
- Use `SharedPreferencesWithCache` abstracted behind a custom `KeyValueStore` interface.
- **Storage limitation**: Preferences are ONLY for small user/app settings. Never use `SharedPreferences` as a timetable or transit data cache.
- The bootstrap sequence safely falls back to an `InMemoryKeyValueStore` if SharedPreferences initialization fails, allowing the app to launch.

## Consequences

- Configuration is resolved safely at compile time and fail-fast at startup.
- The app remains resilient to storage failures.
- Heavy transit caching will require a separate, robust solution (e.g., SQLite/Isolate) in the future.

## Alternatives Considered

- **.env files via flutter_dotenv**: Rejected to avoid shipping multiple environment files in the binary and to prefer compile-time constants.
- **Hive / Isar**: Rejected for simple key-value settings as they introduce unnecessary complexity at this stage.
