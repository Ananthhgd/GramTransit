# 0005: Shared Transit Model and Offline Bundled Timetable

**Status:** Accepted
**Date:** 2026-10-15

**Relates to:** ADR 0001 (fulfils its deferred shared-transit-catalog decision; does not supersede it)

## Context

ADR 0001 established a feature-first architecture with selective layering and explicitly deferred creating a shared transit catalog until a real transit-data feature required it. Phase 1 (Transit Catalog & Offline Timetable) is that feature.

System architecture requires schedule-first and guest-first behavior (System ADR 0002). The Passenger application must remain immediately useful to rural village travelers without requiring network connectivity, a backend server, GPS hardware, or user authentication. End-users must be able to open the app and view accurate, scheduled bus timings directly from local assets.

Both the Home screen (upcoming scheduled departures) and the Trip Details screen (full stop sequences and timings) require access to the same stops, routes, and trips. Allowing individual features to construct their own transit models or load disparate data sources would lead to duplicated parsing, competing transit concepts, and synchronization drift. A single canonical transit domain owned by a dedicated feature is necessary.

Rural transit schedules introduce specific domain requirements:
- Timetables frequently include late-night departures operating past midnight (e.g., 24:15) that belong conceptually to the previous operating/service day rather than the calendar day on which they depart.
- Timetable data must be complete and trustworthy. Incomplete, corrupt, or partially parsed schedule data can mislead passengers waiting for infrequent rural transit; silently ignoring missing stops or broken references is unacceptable.

## Decision

We adopt a canonical transit domain and an offline bundled timetable architecture across ten structural decisions:

### D1: Shared Transit Feature Boundary
`lib/features/transit/` owns the canonical transit domain, data representations, and shared providers. Consumer features (such as `home` and `trip_details`) import and consume transit domain models and application providers. They must not create competing transit domain models or data-loading mechanisms. This fulfils the deferred shared-transit-catalog decision of ADR 0001 without superseding ADR 0001.

### D2: Minimal Canonical Model
We define a focused, immutable domain model representing transit catalog and schedule entities:
- **Identifier value objects:** `StopId`, `RouteId`, and `TripId` enforce non-empty string invariants.
- **Multilingual text:** `LocalizedText` encapsulates English text with optional Kannada and Malayalam fields.
- **Schedule time:** `ServiceTime` represents clock times spanning `00:00` to `47:59` to support service days extending past midnight.
- **Operating days:** `ServiceDays` models weekly recurrence (Monday through Sunday) with date-matching logic.
- **Catalog entities:** `TransitStop` (id, name), `TransitRoute` (id, shortName, longName), and `StopTime` (stopId, arrivalTime, departureTime).
- **Schedule entities:** `ScheduledTrip` (id, routeId, serviceDays, ordered stopTimes) and `Timetable` (info, stops, routes, trips).
- **Metadata:** `TimetableInfo` (datasetVersion, isSampleData).

Derived, non-stored concepts are modeled separately from the core catalog:
- `TripOccurrence` represents a scheduled trip projected onto an absolute calendar date for a specific queried stop.
- `UpcomingTrips` holds grouped results (`current` and `nextLater`) for upcoming departures at a stop.
- Destination stop names are derived from the trip's ordered stop sequence (its final stop time). Trip Details derives origin and destination stop names for presentation.
- Direction is not modeled as a canonical entity attribute.

GTFS-scale concepts (shapes, calendar exceptions, block IDs, fare attributes, complex transfer rules) are excluded as they are unnecessary for Phase 1.

### D3: Service-Day Semantics
Schedules operate on service days (operating days) rather than calendar dates:
- `ServiceTime` accepts hours from `00` to `47` and minutes from `00` to `59`.
- Times with hour >= 24 (e.g., `24:15`) represent late-night runs belonging to the previous operating day's service.
- Trips specify their active days via `ServiceDays`. Calendar-date exceptions and holiday calendars are not currently modeled.

### D4: Boardable-Departure Semantics
The pure domain function `findUpcomingTrips` calculates boardable departures from a queried stop:
- The queried stop must not be the trip's terminal stop (`stopIndex < trip.stopTimes.length - 1`), as passengers cannot board a terminating bus.
- Departures that have already passed relative to the query minute are excluded. Departures within the query minute are included.
- Immediate departures (`current`) evaluate candidate service dates for yesterday and today (handling after-midnight runs).
- If no immediate departures exist, the search expands across the subsequent seven service dates to populate `nextLater`.

### D5: Bundled Versioned Timetable Snapshot
Timetable data is bundled as a static JSON asset:
- Asset path: `assets/transit/timetable.json`.
- Top-level schema contains: `schemaVersion` (integer, currently 1), `datasetVersion` (string), `isSampleData` (boolean), `stops`, `routes`, and `trips`.
- The bundled asset is a Phase 1 local data source, not a permanent backend API contract.
- Timetable metadata carries `isSampleData`. The current bundled dataset is marked as sample data (`isSampleData: true`). When this flag is true, the UI displays an explicit sample-data notice indicating that the timetable is for testing and not for real travel.

### D6: Fail-Closed Validation and Invariants
Timetable data parsing enforces all-or-nothing validation before domain construction:
- Format errors (unsupported schema versions, missing fields, malformed time strings, out-of-order stop times, duplicate identifiers, or missing referential links between trips, routes, and stops) throw `TimetableFormatException` with exact JSON path context.
- Domain entities strictly enforce runtime invariants upon construction.
- The data layer translates known format and asset errors to `DataFormatFailure`. Corrupt or invalid datasets fail completely and visibly rather than rendering partial or silently broken schedules. Programming bugs are not reclassified as data format failures.

### D7: Repository Boundary
Data access is isolated behind a clean contract:
- `TimetableRepository` interface in `lib/features/transit/domain/timetable_repository.dart` defines `Future<Timetable> loadTimetable()`.
- `BundledTimetableRepository` in `lib/features/transit/data/` implements the contract using Flutter's `AssetBundle`.
- The complete timetable snapshot is loaded and parsed into memory.
- Successful loads are memoized in memory for the lifecycle of the repository.
- Failed loads leave the cache empty, allowing future load attempts to retry.
- In Riverpod, `timetableProvider` sets `retry: (_, _) => null`, disabling automatic Riverpod retry loops. Retries are explicitly triggered through the UI refresh path (`ref.refresh(timetableProvider)`).
- The durable architectural boundary is the canonical transit domain and `TimetableRepository` interface. Future remote caching or backend integrations can replace the repository implementation without altering consumer features.

### D8: Deterministic Time
All time-dependent logic is fully decoupled from wall-clock reads:
- The `Clock` interface (`lib/core/time/clock.dart`) abstracts current time reads. `SystemClock` provides the production default.
- `clockProvider` provides `Clock` to the application.
- `minuteTickerProvider` (`StreamProvider.autoDispose<DateTime>`) emits on wall-clock minute boundaries with automatic retry disabled.
- Schedule queries pass explicit `DateTime` values into pure domain functions (`findUpcomingTrips(..., now: ...)`).
- Timezone handling: `SystemClock` uses device-local `DateTime.now()`, and `ServiceTime.toDateTime` constructs local `DateTime` instances. The application operates in the device's local time zone and does not enforce or configure Indian Standard Time (IST).

### D9: Schedule-Only Presentation
All timetable-derived user interfaces are strictly scheduled information:
- A persistent schedule disclosure note (`"Scheduled times. Actual times may vary."`) is displayed on both Home and Trip Details screens.
- User-facing copy must never imply realtime tracking, vehicle punctuality, live delays, or estimated time of arrival (ETA).

### D10: Storage Boundary
Consistent with ADR 0003, `KeyValueStore` / `SharedPreferences` remains strictly reserved for small user preferences (such as theme mode). It is never used as a storage mechanism or cache for transit timetable data.

## Consequences

### Positive
- **Complete offline capability:** The app delivers immediate transit timetable utility upon first launch without network or server dependencies.
- **Single transit vocabulary:** All features share canonical domain models, eliminating model duplication and divergent schedule logic.
- **Testability and determinism:** Injected time abstractions and pure domain functions enable comprehensive, deterministic unit testing without wall-clock delays.
- **Fail-closed integrity:** Corrupted or invalid timetable data fails visibly with localized error feedback rather than presenting misleading partial schedules.
- **Architectural flexibility:** Future data sources (remote APIs, SQLite caching) can be introduced behind the `TimetableRepository` boundary without changing consumer features.

### Accepted Limitations
- **Bundled updates:** Updating transit schedules currently requires distributing an updated application asset or package.
- **In-memory footprint:** The entire timetable snapshot is loaded and held in memory. This is appropriate for current rural route scales but may require indexed storage for large multi-district datasets.
- **No calendar exceptions:** Holiday schedules, seasonal variations, and date-specific cancellations are not yet represented.
- **Strict all-or-nothing parsing:** A single validation error in the timetable asset rejects the entire dataset.
- **Device-local time zone:** Times are evaluated against the device's local clock without server-coordinated or regional timezone enforcement.

### Alternatives Considered
1. **Per-feature transit models:** Rejected because having Home and Trip Details maintain separate stop and trip models leads to duplication, inconsistent behavior, and data drift.
2. **Local database (SQLite/Isar) for Phase 1:** Rejected as unnecessary overhead for a small, read-only bundled timetable snapshot. A database may be introduced later when remote caching or large datasets warrant it.
3. **SharedPreferences for timetable storage:** Rejected because key-value preferences are inappropriate for relational schedule data and directly violates the storage boundary established in ADR 0003.
4. **Typed in-code timetable fixtures:** Rejected for production timetables because bundled JSON data files can be validated, generated, and replaced independently of Dart application code.
5. **Full GTFS model and importer:** Rejected as disproportionate for Phase 1 rural bus schedule requirements. The minimal canonical model captures only the concepts needed.
6. **Code-generated serialization (`json_serializable` / `freezed`):** Rejected to keep the toolchain lightweight, eliminate build-runner overhead, and allow explicit fail-closed path reporting via custom DTOs and mappers.
7. **Best-effort partial timetable loading:** Rejected because omitting invalid stops or trips silently presents incomplete schedules that misinform rural travelers.
8. **Terminal-inclusive upcoming departures:** Rejected because passengers cannot board a bus at its final destination stop.
9. **Default use-case classes:** Rejected in accordance with ADR 0001; pure domain functions (`findUpcomingTrips`) and Riverpod providers provide clean logic boundaries without extra boilerplate classes.
10. **Assert-only domain invariants:** Rejected because Dart assertions are stripped in release builds, whereas timetable integrity requires guaranteed runtime validation.
