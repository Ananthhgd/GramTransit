# 0007: Stops, Routes, and Timetable Browsing

**Status:** Accepted
**Date:** 2026-10-23

**Relates to:** ADR 0001 (Feature-first Selective Layering), ADR 0002 (Riverpod and Navigation), ADR 0005 (Shared Transit Model and Offline Bundled Timetable), ADR 0006 (Direct Journey Discovery and Journey Search)

## Context

Phase 1 (ADR 0005) established the canonical transit domain and offline bundled timetable architecture, enabling passengers to view scheduled departures from a selected stop and inspect individual trip stop sequences. Phase 2 (ADR 0006) introduced point-to-point direct journey search between a boarding stop and an alighting stop.

In Phase 3 (Stops, Routes & Timetable Browsing), passenger discovery expands from search queries to full catalog exploration:
> *"I want to explore all stops and routes in the network, see which buses serve my village stop, see upcoming departures from that stop, jump directly into journey planning from that stop, and inspect the exact operating patterns and scheduled trips for any bus route."*

System architectural principles (System ADR 0002 and Passenger ADR 0005) mandate that the application remains:
- **Schedule-first:** Baseline utility is driven strictly by scheduled timings from bundled timetable data. Live vehicle positions, arrival delays, and ETAs are non-goals for this phase.
- **Guest-first:** No user accounts, login, or authentication are required.
- **Offline-capable:** All browsing, filtering, pattern grouping, and schedule evaluations operate locally from the bundled timetable snapshot without backend APIs, network requests, or GPS/map dependencies.
- **Explicitly Excluded:** Maps, GPS, live vehicle tracking, realtime ETAs, backend/network communication, user accounts/auth, fares/ticketing, transfers/interchanges, favorites, and push notifications are strictly deferred.

To support this comprehensive browsing capability cleanly, several architectural questions had to be resolved:
1. How should operated route patterns (variants, reverse patterns, short turns) be represented without polluting `TransitRoute` metadata?
2. How should the derived `RouteVariant` projection be bounded and lifecycle-managed?
3. Where does Browse feature logic belong relative to the canonical transit domain?
4. How should data loading and state management for browsing stops and routes be structured without speculative repositories or stateful controllers?
5. How should screen presentation interact with application routing while maintaining high testability and component reusability?
6. How should invalid path IDs be handled compared to valid syntactically but unknown canonical IDs?
7. How should deterministic ordering be guaranteed across stops, routes, variants, and trips?
8. How should shared formatting (e.g. weekdays, service times) be refactored across features without violating architectural layer boundaries?

## Decision

We adopt a stops, routes, and timetable browsing architecture across ten structural decisions:

### D1: Route Patterns Derived from Scheduled Trips (Not Added to TransitRoute)
Phase 3 did **not** add a stop sequence to `TransitRoute`. `TransitRoute` remains strictly route identity and metadata (`id`, `shortName`, `longName`).
- In real-world rural transit, a single route identity frequently operates multiple distinct physical patterns: outbound vs. inbound (reverse), short-turn runs terminating early, branch variants serving different intermediate villages, and express variations.
- Attempting to force an ordered stop list into `TransitRoute` would either force unnatural synthetic splitting of route identities or fail to represent actual operational variations.
- Operated stop patterns are dynamically derived from the stop sequences of scheduled trips (`ScheduledTrip.stopTimes`).

### D2: RouteVariant as a Pure Derived Domain Value Object
We introduce `RouteVariant` in `lib/features/transit/domain/route_catalog.dart` as the single new derived domain value object for Phase 3:
- Encapsulates: `routeId`, ordered unmodifiable `stopIds`, non-empty unmodifiable `trips`, derived `firstStopId`, derived `lastStopId`, and derived `stopCount`.
- Runtime invariants strictly enforced in constructor:
  - At least two stops (`stopIds.length >= 2`).
  - At least one trip (`trips.isNotEmpty`).
  - Every contained trip must have matching `trip.routeId == routeId`.
  - Every contained trip must have the exact same ordered stop sequence as `stopIds`.
- `RouteVariant` references canonical `ScheduledTrip` objects. It is derived on demand and is **never** persisted or cached.

### D3: Deterministic Catalog Projections (`routeVariants` and `routesServingStop`)
Catalog projection functions are implemented as pure domain functions in `lib/features/transit/domain/route_catalog.dart`:
- **`routeVariants(Timetable, RouteId)`:**
  - Validates route existence; throws `ArgumentError('Route not found in timetable')` if `routeId` is not in `timetable.routes`.
  - Returns an empty unmodifiable list if the route exists but has zero scheduled trips.
  - Groups trips strictly by identical ordered `StopId` sequence.
  - Reverse patterns, short-turn patterns, and differing intermediate stops remain separate variants.
  - Differences in operating days (`serviceDays`) or trip departure times alone do **not** split variants.
  - Variant ordering strictly follows the first appearance of any trip belonging to that variant in canonical `timetable.trips` order.
  - Trips inside each variant are sorted deterministically by:
    1. First-stop departure `ServiceTime` (preserving late-night `24:xx`–`47:xx` hours after `23:xx`).
    2. `TripId.value` lexicographically as a tie-breaker.
- **`routesServingStop(Timetable, StopId)`:**
  - Validates stop existence; throws `ArgumentError('Stop not found in timetable')` if `stopId` is not in `timetable.stops`.
  - Returns an empty unmodifiable list if the stop exists but is not visited by any scheduled trip.
  - Origin, intermediate, and terminal visits all qualify as serving the stop.
  - Serving `RouteId`s are deduplicated.
  - Returned routes preserve canonical `timetable.routes` order.

### D4: Shared Weekday Formatting in Core
To eliminate duplication between Trip Details and Route Details without violating architectural boundaries, weekday formatting was refactored in P3.2:
- Feature-agnostic helpers `formatShortWeekday(context, int)` and `formatShortWeekdays(context, Iterable<int>)` were added to `lib/core/l10n/date_time_formatting.dart`.
- The helpers accept standard integer weekday constants (`DateTime.monday` through `DateTime.sunday`), deduplicating and sorting them from Monday to Sunday.
- `lib/core/` does **not** import `lib/features/transit/` or `ServiceDays`, adhering strictly to architectural rule `G1`.
- Feature presentation layers (`trip_display_format.dart`, `browse_display_format.dart`) map `ServiceDays` into weekday integers before calling the core helper. Existing Trip Details presentation remained unchanged.

### D5: Browse Feature Application Boundary
A single feature module is created under `lib/features/browse/`:
- Contains `application/` and `presentation/` layers only.
- Does not define a local `domain/` layer; canonical domain projections remain in `lib/features/transit/domain/route_catalog.dart`.
- Introduces two application providers in `browse_providers.dart`:
  - `stopDetailsProvider`: `Provider.autoDispose.family<AsyncValue<StopDetails?>, StopId>`
    - `StopDetails` encapsulates canonical `TransitStop` and unmodifiable `List<TransitRoute>` serving the stop.
    - Watches `timetableProvider`; propagates loading and error states.
    - Known stop -> `AsyncData(StopDetails)`. Known unused stop -> `AsyncData(StopDetails)` with empty routes list. Syntactically valid but unknown stop -> `AsyncData(null)`.
  - `routeDetailsProvider`: `Provider.autoDispose.family<AsyncValue<RouteDetails?>, RouteId>`
    - `RouteDetails` encapsulates canonical `TransitRoute` and unmodifiable `List<RouteVariant>`.
    - Watches `timetableProvider`; propagates loading and error states.
    - Known route -> `AsyncData(RouteDetails)`. Known zero-trip route -> `AsyncData(RouteDetails)` with empty variants list. Syntactically valid but unknown route -> `AsyncData(null)`.
- No Browse-specific controllers, Notifiers, use cases, caching layers, or persistence were introduced.
- Browse reuses existing shared providers: `timetableProvider`, `stopSearchProvider(StopSearchQuery(query: query))`, and `upcomingTripsProvider(stopId)`.

### D6: Stops Browsing UI
Implemented in `lib/features/browse/presentation/`:
- **Stops List (`/stops` -> `StopsScreen`):**
  - Displays all stops in canonical timetable order when search query is empty.
  - Filters and ranks stops using existing `searchStops` domain algorithm when searching.
  - Unused stops remain visible and searchable.
  - Displays compact sample data notice when `timetable.info.isSampleData` is true.
  - Displays `GtEmptyState` when no stops match the search query.
- **Stop Details (`/stops/:stopId` -> `StopDetailsScreen`):**
  - Displays canonical stop name header.
  - Displays standard sample data notice when applicable.
  - Prominent "Plan journey from here" button passing `stopId` to Journey Search (`/journeys?from=<StopId>`).
  - Lists routes serving the stop (with route short name chips and long names).
  - Lists upcoming scheduled departures via `upcomingTripsProvider` using `StopUpcomingTripCard`.
  - Displays scheduled-times disclaimer: `"Scheduled times. Actual times may vary."`
  - Tapping departure cards navigates to Trip Details (`/trips/:tripId`).
  - Displays `GtEmptyState` not-found UI if the stop is unknown.
- Browse screens are router-agnostic and driven entirely by callbacks (`onStopTap`, `onPlanJourney`, `onTripTap`, `onBack`).

### D7: Routes Browsing UI and Endpoint Time Semantics
Implemented in `lib/features/browse/presentation/`:
- **Routes List (`/routes` -> `RoutesScreen`):**
  - Displays all routes in canonical timetable order, including routes with zero scheduled trips.
  - Displays compact sample data notice when applicable.
  - Tapping a route invokes `onRouteTap` to navigate to Route Details.
- **Route Details (`/routes/:routeId` -> `RouteDetailsScreen`):**
  - Displays route short name badge and long name header.
  - Displays standard sample data notice when applicable.
  - Renders one distinct UI section card per derived `RouteVariant`.
  - For each variant, renders the complete ordered stop sequence with numbered stop circles and stop names.
  - Lists scheduled trips operating that variant with departure and arrival times and operating days summary.
  - Displays empty state (`routeNoScheduledTrips`) if the route has zero variants/trips.
  - Displays scheduled-times note (`BrowseScheduledTimesNote`) only when variants exist.
  - Tapping a trip row invokes `onTripTap` to navigate to Trip Details.
  - Displays `GtEmptyState` not-found UI if the route is unknown.
- **Trip Row Endpoint Time Semantics:**
  - First-stop departure and last-stop arrival times are evaluated and formatted **independently**.
  - Times with hour >= 24 are displayed as normalized clock times (`00`–`23`) with a visible `+1` badge.
  - Accessibility semantics independently describe departure vs. arrival and next-day meaning (`routeDepartureEndpointSemantics`, `routeArrivalEndpointSemantics`, `tripDetailsNextDaySemantics`).
  - Next-day status is **not** inferred at the row level; an early morning arrival does not automatically mark a departure as next-day.

### D8: Root-Level Routing and Two-Stage ID Validation
Four root-level routes are registered in `lib/app/router/app_router.dart`:
- `/stops` (name: `AppRoutes.stops`)
- `/stops/:stopId` (name: `AppRoutes.stopDetails`)
- `/routes` (name: `AppRoutes.routes`)
- `/routes/:routeId` (name: `AppRoutes.routeDetails`)
- Mounted on the root navigator (`parentNavigatorKey: _rootNavigatorKey`), overlaying the bottom navigation bar.
- Paths use lowercase plural nouns; path parameters are parsed via typed domain constructors (`StopId(raw)`, `RouteId(raw)`) wrapped in `try/on ArgumentError`. No regular expression validation is used.
- **Two Distinct Failure Modes:**
  - **Stage 1 (Router Syntactic Validation):** If a path parameter is missing, empty, or fails value-object validation (e.g. whitespace-only), `parsePathStopId` or `parsePathRouteId` returns `null`. The router builder immediately renders a fallback `Scaffold` containing `GtEmptyState` with back navigation.
  - **Stage 2 (Screen Semantic Validation):** If a path parameter is syntactically valid but does not exist in the loaded timetable, navigation succeeds to `StopDetailsScreen` or `RouteDetailsScreen`. The underlying provider (`stopDetailsProvider` or `routeDetailsProvider`) resolves to `AsyncData(null)`, and the screen renders the established Browse not-found `GtEmptyState`.
- Unmatched URL paths continue to fall back to `RouteNotFoundScreen`.

### D9: Home Explore Section and State Independence
An exploration entry section (`HomeExploreSection`) is integrated into `HomeScreen`:
- Situated between `SearchEntryPlaceholder` and `UpcomingDeparturesSection`.
- Provides two accessible action cards: "All stops" (`onAllStopsTap`) and "All routes" (`onAllRoutesTap`).
- `HomeScreen` continues to own session-only `StopId? _selectedStopId` in `_HomeScreenState` (Model H-A).
- Exploring stops or routes does not mutate or clear `_selectedStopId`.
- No global Riverpod state or stateful Home controller was introduced.

### D10: Sample Data and Testing Baseline
- Phase 3 did **not** introduce a `sample-v3` dataset. It continues to use the Phase 2 `sample-v2` timetable snapshot (`assets/transit/timetable.json`, `isSampleData: true`).
- Disclosures are strictly enforced:
  - Sample-data notice: `"Sample timetable for testing — not for real travel."` (compact in lists, standard in details; suppressed during loading, error, or not-found states).
  - Scheduled-times note: `"Scheduled times. Actual times may vary."`
- Complete offline capability: all Browse features operate with zero network dependencies.
- Verified test suite at freeze: 485/485 passing tests, 0 analyzer issues, green production configuration test, and Passenger CI #25 green.

## Consequences

### Positive
- **No Domain Model Inflation:** `TransitRoute` remains simple and focused on identity; complex operated variations are derived as pure `RouteVariant` projections.
- **Accurate Real-World Pattern Representation:** Reverse routes, short turns, and branch variations are represented cleanly as distinct variants without synthetic route fragmentation.
- **Zero Network Dependency:** The entire catalog of stops, routes, variants, and departures is browseable fully offline.
- **Reusable Application Architecture:** Browse screens are router-agnostic presentation components driven by callbacks, enabling exhaustive widget testing with injected fakes.
- **Safe Deep Linking and Resilient Routing:** Two-stage ID parsing guarantees that neither syntactically malformed URLs nor stale/unknown stop or route IDs crash the app or throw unhandled routing exceptions.
- **Layer Boundary Integrity:** Shared weekday formatting lives in `lib/core/` without importing domain models, satisfying architecture guardrail `G1`.

### Accepted Limitations
- **No Map or GPS Visualization:** Stops and routes are presented purely as structured lists and timelines; interactive map rendering and geolocation auto-selection are deferred.
- **Sample Data Scope:** Data remains marked as testing sample data (`sample-v2`) and does not represent live production bus routes.
- **No Realtime Awareness:** Displays scheduled timings only; does not reflect vehicle positions, real-world delays, or trip cancellations.
- **Direct Journeys Only:** Journey planning supports direct services only; transfers, interchanges, and multi-leg journey planning are not implemented.

### Alternatives Considered
1. **Adding Stop Sequence Directly to `TransitRoute`:** Rejected because transit routes operate multiple patterns (outbound, inbound, short turns, express). Forcing a single stop sequence into `TransitRoute` misrepresents reality and breaks down for bidirectional or branching routes.
2. **Persisting or Caching `RouteVariant` in Repositories:** Rejected because deriving variants from `Timetable.trips` is an in-memory operation taking single-digit milliseconds for bundled datasets. Caching would introduce cache synchronization risks without measurable performance benefit.
3. **Dedicated `BrowseRepository` or Stateful Browse Controllers:** Rejected because `Timetable` already holds all necessary catalog data in memory. Deriving projections via pure functions and Riverpod family providers satisfies all requirements without speculative architecture.
4. **Router-Level Timetable Lookups and Redirects:** Rejected because timetable loading is asynchronous. Forcing the synchronous `GoRouter` configuration to await timetable loads for validation would introduce loading latency, navigation race conditions, and tight coupling. Two-stage validation keeps routing synchronous and robust.
5. **Combining Home and Browse into a Single Feature:** Rejected because Home represents the primary passenger dashboard (search entry and current departures), whereas Browse represents secondary full-catalog exploration. Keeping `browse/` as a distinct feature follows selective layering (ADR 0001).
