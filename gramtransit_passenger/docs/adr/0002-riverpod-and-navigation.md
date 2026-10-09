# 0002: Riverpod and Navigation

**Status:** Accepted
**Date:** 2026-10-09

## Context

The app requires a robust state management and navigation solution capable of handling async data and deep linking.

## Decision

- **Riverpod 3** will be used for state management and dependency injection.
- Use **manual providers** only. No code generation (`riverpod_generator`).
- Avoid legacy provider patterns (`StateNotifierProvider`, `ChangeNotifierProvider`). Use `Notifier` and `AsyncNotifier`.
- **GoRouter** will be used for navigation.
- Implement `StatefulShellRoute.indexedStack` to preserve state across bottom navigation tabs.
- Use named routes with lowercase plural paths (e.g., `/settings`).
- No artificial waiting splash route; the app resolves state immediately or shows localized loading components.

## Consequences

- Consistent, modern state management without the build step overhead of code generation.
- Declarative routing supports future deep-linking easily.

## Alternatives Considered

- **Provider / BLoC**: Rejected in favor of Riverpod's compile-time safety and async handling.
- **Riverpod with Codegen**: Rejected to keep the toolchain lightweight and minimize build times.
