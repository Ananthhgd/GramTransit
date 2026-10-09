# 0001: Feature-first Selective Layering

**Status:** Accepted
**Date:** 2026-10-09

## Context

We need an organizational structure for the Flutter app that scales without forcing unnecessary boilerplate.

## Decision

- Use a **feature-first** folder structure under `lib/features/`.
- Apply **selective layering**: create `presentation/`, `application/`, `domain/`, and `data/` layers inside a feature *only when useful*.
- No default "use-case" layer unless business logic dictates it.
- No empty "future" feature folders.
- `lib/core/` houses feature-agnostic infrastructure. `lib/app/` is the composition root.
- A shared transit catalog feature is deferred until the first real data feature requires it.

## Consequences

- Reduces boilerplate for simple features.
- Keeps related code together.
- Requires discipline to prevent layers from blurring when they do exist.

## Alternatives Considered

- **Strict Clean Architecture**: Rejected as too heavy and verbose for simple UI-driven features.
- **Layer-first**: Rejected because it separates related feature logic across the entire repository.
