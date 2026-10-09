# 0004: Testing, CI, and Architecture Guardrails

**Status:** Accepted
**Date:** 2026-10-09

## Context

We need to ensure long-term maintainability, prevent regressions, and enforce architecture rules without adding heavy tooling.

## Decision

- Prefer **fakes** over mocks. No mocking dependency (`mockito`, `mocktail`).
- Use small, focused test helpers rather than massive DSLs or page objects.
- Tests must use **public APIs** only.
- Carefully use `pump()` instead of `pumpAndSettle()` when indeterminate animations are present.
- Implement **zero-dependency guardrail tests** in Dart to enforce folder dependencies and import rules natively.
- Commit generated `l10n` files to the repository.
- CI will use a pinned Flutter version and enforce a zero-warning analyzer policy.

## Consequences

- Tests are less brittle and easier to maintain.
- Architecture rules are enforced in CI without relying on custom linter packages.
- CI is fast and deterministic.

## Alternatives Considered

- **custom_lint / dart_code_metrics**: Rejected to keep dependencies light and avoid maintaining custom lint plugins.
- **Mocktail**: Rejected because fakes provide a more reliable and refactor-friendly testing foundation.
