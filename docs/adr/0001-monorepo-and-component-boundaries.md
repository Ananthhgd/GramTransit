# 0001: Monorepo and Component Boundaries

**Status:** Accepted
**Date:** 2026-10-09

## Context

GramTransit will consist of multiple deployable components (passenger mobile app, driver mobile app, admin web app, backend server). We need a strategy to organize the source code, CI/CD, and documentation.

## Decision

- We will use a **monorepo** for the entire GramTransit system.
- Each deployable component will have its own top-level directory (e.g., `gramtransit_passenger/`).
- System-level documentation exists at the repository root (`docs/`).
- Component-specific documentation exists within the component's directory.
- CI/CD will be component-scoped using path filtering to trigger workflows only when relevant files change.

## Consequences

- Simplifies dependency management and sharing of schemas/contracts in the future.
- Keeps all transit-related context in one place.
- Requires careful path filtering in GitHub Actions to prevent unrelated component builds.

## Alternatives Considered

- **Multi-repo**: Rejected due to the overhead of managing multiple repositories, cross-repo pull requests, and fragmented documentation for a tightly coupled system.
