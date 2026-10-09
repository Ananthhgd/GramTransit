# 0002: Schedule-first and Guest-first Principles

**Status:** Accepted
**Date:** 2026-10-09

## Context

GramTransit targets rural users who often face poor network connectivity and may be hesitant to create accounts for public services.

## Decision

- **Schedule-first**: The baseline functionality must rely on offline-capable scheduled transit information. Realtime data is an enhancement and must gracefully degrade to schedules when unavailable.
- **Guest-first**: Public transit information must not require login. Authentication is strictly reserved for personalized, synchronized functionality (e.g., cross-device favorites).

## Consequences

- The architecture must support robust local caching of schedules.
- Features cannot blindly assume a persistent, high-speed network connection.
- Development must prioritize the unauthenticated user flow.

## Alternatives Considered

- **Realtime-only**: Rejected because it fails completely in rural network dead zones.
- **Mandatory accounts**: Rejected as it introduces friction and reduces adoption for a public utility.
