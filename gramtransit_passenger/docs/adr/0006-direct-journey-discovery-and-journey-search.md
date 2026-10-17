# 0006: Direct Journey Discovery and Journey Search

**Status:** Accepted
**Date:** 2026-10-17

**Relates to:** ADR 0001 (Feature-first Selective Layering), ADR 0002 (Riverpod and Navigation), ADR 0005 (Shared Transit Model and Offline Bundled Timetable)

## Context

Phase 1 (ADR 0005) established the canonical transit domain and offline bundled timetable architecture, enabling passengers to view scheduled departures from a selected boarding stop and inspect individual trip stop sequences.

In Phase 2 (Direct Journey Discovery & Journey Search), passenger requirements expand from single-stop departure boards to destination-oriented journey planning:
> *"I know the stop I am boarding from and the stop I want to travel to. Show me which scheduled direct bus journeys can take me there."*

System architectural principles (System ADR 0002 and Passenger ADR 0005) mandate that the application remains:
- **Schedule-first:** Baseline utility is driven strictly by scheduled timings from bundled timetable data. Live vehicle positions, arrival delays, and ETAs are non-goals for this phase.
- **Guest-first:** No user accounts, login, or authentication are required.
- **Offline-capable:** All search, filtering, and schedule evaluations operate locally without backend APIs, network requests, or GPS/map dependencies.

To support this passenger flow cleanly, several architectural questions had to be resolved:
1. Should journey search introduce a separate domain model or extend the canonical transit feature (`lib/features/transit/`)?
2. How should direct journey eligibility be evaluated across service days without duplicating Phase 1's boarding and service-day algorithms?
3. How should stop search be implemented offline with deterministic ranking?
4. How should boarding selection state be managed between the Home screen and Journey Search?
5. How should routing and deep-linking query parameters (`/journeys?from=...&to=...`) be parsed and validated safely when timetable data loads asynchronously?

## Decision

We adopt a direct journey discovery and search architecture across ten structural decisions:

### D1: Extension of the Canonical Transit Domain
Rather than creating a separate or competing journey domain, we extend the canonical transit domain under `lib/features/transit/domain/`:
- **`ScheduledJourney`:** An immutable domain value object representing a single scheduled direct journey from a `boardingStopId` to a downstream `alightingStopId` for a specific service occurrence. It encapsulates `tripId`, `routeId`, `routeShortName`, `routeLongName`, `tripHeadsign`, `boardingStopId`, `boardingStopName`, `alightingStopId`, `alightingStopName`, `serviceDate`, `scheduledDeparture`, and `scheduledArrival`.
  - Invariants: `boardingStopId != alightingStopId`, and `!scheduledArrival.isBefore(scheduledDeparture)` (arrival must not precede departure; equal times with zero duration are permitted).
  - Helper properties: `scheduledDuration` (`scheduledArrival.difference(scheduledDeparture)`) and `arrivesOnLaterCalendarDay` (boolean flag indicating calendar date rollover).
- **`UpcomingJourneys`:** An immutable domain result holding `boardingStopId`, `alightingStopId`, `queryTime`, `current` (unmodifiable list of eligible journeys), and `nextLater` (unmodifiable list of future service-day journeys).

### D2: Direct Journey Eligibility and Stop-Sequence Evaluation
A scheduled trip provides an eligible direct journey if and only if:
1. The trip visits both the boarding stop and the alighting stop.
2. The alighting stop appears **strictly after** the boarding stop in the trip's scheduled stop sequence (`alightingIndex > boardingIndex`).

Key characteristics:
- Eligibility is governed strictly by sequential stop order in `trip.stopTimes`, not clock-time strictness.
- Same-time arrivals/departures (`scheduledArrival >= scheduledDeparture`) are structurally valid; zero-duration journeys are permitted by the domain model and formatted in presentation as `"Less than 1 min"`.
- Phase 2 scope is strictly direct journeys. Multi-leg transfers and route interchanges are excluded.

### D3: Shared Boarding Semantics and Candidate Algorithm Reuse
To prevent divergent scheduling logic, Phase 1's candidate evaluation logic was refactored and extracted into a shared private domain function `_evaluateBoardingCandidates` in `lib/features/transit/domain/upcoming_trips_logic.dart` (`upcoming_journeys_logic.dart` is `part of 'upcoming_trips_logic.dart'`):
- Both `findUpcomingTrips` and `findUpcomingJourneys` invoke this shared evaluation pipeline.
- Common semantics enforced:
  - Service-day matching (`trip.serviceDays.operatesOn(candidateDate)`).
  - Late-night service-day mapping (`ServiceTime` with hours `00` through `47`).
  - Exclusion of passed departures relative to the query minute (`departureTimeAbsolute.isBefore(queryMinute)`).
  - Exclusion of boarding at a trip's final terminal stop (`boardingStopIndex == trip.stopTimes.length - 1`).
  - Downstream alighting stop enforcement when `alightingStopId` is supplied (`alightingIndex > boardingIndex`).
  - Evaluation of yesterday and today candidate service dates (offsets `-1` and `0`) for immediate `current` departures.
  - Fallback evaluation of the subsequent seven service dates (offsets `+1` through `+7`) for `nextLater` if and only if `current` contains no eligible journeys.
  - Deterministic sorting by `scheduledDeparture`.

### D4: Offline Deterministic Stop Search
Stop search is implemented as a pure domain function `searchStops` in `lib/features/transit/domain/stop_search.dart`:
- Evaluates against in-memory `Timetable.stops` with zero network overhead.
- Normalization via `normalizeStopSearch`: converts text to lowercase; strips `.`, `'`, and `’`; replaces `-`, `–`, `/`, `,`, `(`, and `)` with spaces; trims whitespace; collapses repeated internal whitespace into a single space.
- Deterministic ranking into four buckets when query is non-empty:
  1. Exact normalized match.
  2. Normalized stop name starts with normalized query.
  3. Any word in normalized stop name starts with normalized query.
  4. Other substring match.
- Ties within buckets and empty queries preserve original timetable order.
- Accepts optional `excludedStopId` to exclude the currently selected boarding stop from destination results.
- Duplicate stop names (physical stops sharing identical names) remain distinct entities identified by unique `StopId`.
- Phase 2 supports English stop names; transliteration and regional script matching are deferred.

### D5: Reactive Riverpod Providers
Transit providers in `lib/features/transit/providers/transit_providers.dart` provide state for stop search and journey calculation without introducing unnecessary stateful controllers:
- Parameter keys: `StopSearchQuery(query, excludedStopId)` and `JourneyQuery(boardingStopId, alightingStopId)` enforce value equality and hashing.
- `stopSearchProvider`: `Provider.autoDispose.family<AsyncValue<List<TransitStop>>, StopSearchQuery>` searches stops against `timetableProvider`.
- `upcomingJourneysProvider`: `Provider.autoDispose.family<AsyncValue<UpcomingJourneys>, JourneyQuery>` joins `timetableProvider` and `minuteTickerProvider`, synchronously re-evaluating on minute boundaries with seamless cached transitions.
- No separate Journey Search controller or Riverpod view-model provider was created; presentation widgets observe these providers directly.

### D6: Home State Ownership (Model H-A)
The Home screen (`lib/features/home/presentation/home_screen.dart`) owns the session-local `StopId? _selectedStopId` in `_HomeScreenState`:
- `UpcomingDeparturesSection` is controlled by `HomeScreen` via passed parameters (`selectedStopId` and `onStopSelected`).
- State is session-local and not persisted across application restarts.
- Tapping the search entry placeholder initiates navigation:
  - If `_selectedStopId != null`: navigates to `/journeys?from=<StopId>`.
  - If `_selectedStopId == null`: navigates to `/journeys`.
- Only primitive `StopId` values cross the route boundary; no `TransitStop` or `Timetable` instances are passed in route extras.
- Navigating back from `/journeys` returns to Home with `_selectedStopId` preserved via GoRouter's navigator stack.

### D7: Journey Search Presentation
Presentation is encapsulated in `lib/features/journey_search/presentation/`:
- `JourneySearchScreen` manages local `_boardingStopId` and `_alightingStopId` widget state.
- `JourneyStopSelector` wraps Material 3 `SearchAnchor` for accessible, searchable stop selection.
- Stop swap semantics:
  - Both selected: swaps From and To.
  - From only: previous From becomes To; From is cleared.
  - To only: previous To becomes From; To is cleared.
  - Neither selected: no-op.
  - Selecting From identical to To automatically clears To.
- Reactive results: `JourneyResultsSection` observes `upcomingJourneysProvider` automatically when both distinct stops are chosen. No manual "Submit" or "Search" action button is required.
- Duration formatting (`journey_display_format.dart`): `Duration.zero` renders as `"Less than 1 min"`.
- Notices: Persistent schedule disclosure note (`JourneyScheduledTimesNote`) and sample data banner (`JourneySampleDataNotice`).
- Accessibility: Minimum 48×48 dp touch targets, light/dark theme support, and non-clipped layout at 200% text scale.

### D8: Top-Level Routing and Two-Stage Query Validation
Routing is registered in `lib/app/router/app_router.dart`:
- Route name: `AppRoutes.journeys` (`journeys`), path: `AppRoutes.journeysPath` (`/journeys`).
- Mounted on the root navigator (`_rootNavigatorKey`), overlaying the bottom navigation bar.
- Supported query parameters: `from` and `to`.
- **Two-Stage Validation Model:**
  - **Stage 1 (Router-Level Syntactic Parsing):** `parseQueryStopId` converts raw query strings into `StopId`. Absent, empty, or whitespace-only parameters resolve to `null`. Non-empty trimmed strings produce `StopId`. The router does not perform timetable lookups, redirect, or throw exceptions.
  - **Stage 2 (Screen-Level Semantic Validation):** `JourneySearchScreen` inspects parsed IDs once after the first successful timetable load (`_didSanitizeInitialQuery`). Unknown stops are cleared to `null`; identical `from` and `to` retains `from` and clears `to`; valid distinct stops are retained. Sanitization occurs silently without crashing or rewriting the browser/route URL.

### D9: Bundled Timetable Snapshot Enrichment
The local asset `assets/transit/timetable.json` was enriched to support journey search verification:
- Top-level `schemaVersion` remains `1`.
- `datasetVersion` updated to `"sample-v2"`.
- `isSampleData` remains `true`.
- Added realistic rural stop sequences and overlapping routes while maintaining full compatibility with Phase 1 sample entities.

### D10: Schedule-Only Integrity and Disclosures
All timetable information displayed in Journey Search represents scheduled timings:
- Every journey search view includes the persistent disclosure: `"Scheduled times. Actual times may vary."`
- User-facing copy strictly avoids terms like *"live"*, *"real-time"*, *"arriving in X mins"*, or *"delayed"*.
- When `isSampleData` is true, an explicit notice warns passengers that data is for testing only.

## Consequences

### Positive
- **Complete Offline Utility:** Point-to-point journey planning functions without network access, GPS, or backend servers.
- **Single Transit Vocabulary:** Extends canonical domain models (`lib/features/transit/domain/`), eliminating duplicate schedule models and divergent algorithms.
- **High Testability and Determinism:** Reuses the injected `Clock` and `minuteTickerProvider` abstractions, allowing deterministic testing of journeys across service dates without thread sleeps.
- **Deep-Linkable and Safe:** Supports direct query navigation (`/journeys?from=...&to=...`) with robust two-stage validation that never crashes on malformed or stale stop IDs.
- **Clean Architecture Boundaries:** Presentation depends strictly on domain models and providers, with zero leaky dependencies.

### Accepted Limitations
- **Direct Journeys Only:** Multi-leg journeys requiring transfers between different routes are not supported in Phase 2.
- **English Stop Search:** Stop search normalizes and matches English names only. Multilingual/regional transliteration is deferred.
- **Session-Local Selection State:** Selected stops in Home and Journey Search are not persisted across app process restarts.
- **Sample Timetable Coverage:** Bundled data remains marked as sample data (`sample-v2`) and does not represent real-world operational transit coverage.
- **No Realtime Awareness:** Does not reflect live bus locations, congestion delays, or cancellations.

### Alternatives Considered
1. **Separate Journey Search Transit Model:** Rejected because duplicating stops, routes, and trips leads to synchronization bugs and violates the canonical transit boundary established in ADR 0001 and ADR 0005.
2. **Client-Side Trip Filtering in Widgets:** Rejected because schedule math, service-day rollover, and minute ticker joins belong in pure domain functions and Riverpod providers, not inside Flutter widget trees.
3. **Global Riverpod Controller for Home Stop Selection:** Rejected in favor of session-local widget state (Model H-A). Home stop selection is purely ephemeral UI state and does not justify global application state.
4. **Timetable-Aware Router Redirects:** Rejected because router redirects requiring asynchronous data loading introduce latency, flash-of-redirect artifacts, and tight coupling between GoRouter and data sources. Two-stage validation keeps the router synchronous and fast.
5. **Multi-Leg Journey Planning (Transfers) in Phase 2:** Deferred because rural transit corridors are dominated by direct point-to-point services, and transfer routing requires graph algorithms and connection risk buffers better suited for later phases.
6. **Backend Journey Planning API:** Deferred because offline-first capability is a mandatory baseline requirement for rural passenger transit. Future backend sync will fit behind the existing repository boundary.
