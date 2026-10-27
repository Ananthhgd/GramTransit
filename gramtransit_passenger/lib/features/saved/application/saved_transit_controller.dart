import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/logging/logging_providers.dart';
import 'package:gramtransit_passenger/features/saved/application/saved_transit_providers.dart';
import 'package:gramtransit_passenger/features/saved/domain/saved_transit.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';

/// Controls passenger saved transit preferences (stops and routes).
///
/// Uses the Riverpod 3 [Notifier] API — no code generation.
/// Remains a synchronous [Notifier]; NOT converted to [AsyncNotifier].
///
/// Persistence & State lifecycle:
/// - [build] reads the stored preference synchronously via [SavedTransitRepository].
/// - Mutations publish optimistic state in memory immediately, then persist
///   asynchronously.
/// - Idempotent operations return immediately as no-ops without state assignments
///   or storage writes.
/// - If persistence throws [StorageFailure], the optimistic in-memory state is
///   retained, a warning is logged (without exposing raw saved IDs), and
///   [StorageFailure] is rethrown so the presentation layer can display feedback.
class SavedTransitController extends Notifier<SavedTransit> {
  @override
  SavedTransit build() {
    // ref.read is appropriate here: SavedTransitRepository is a stable dependency
    // that does not itself expose reactive state.
    return ref.read(savedTransitRepositoryProvider).read();
  }

  /// Saves [stopId].
  ///
  /// If [stopId] is already saved, this is an idempotent no-op and returns immediately.
  /// Otherwise, updates in-memory state immediately, then asynchronously persists the snapshot.
  Future<void> saveStop(StopId stopId) async {
    final next = state.withStop(stopId);
    if (identical(next, state)) return;

    state = next;
    await _persist(next);
  }

  /// Removes [stopId] from saved stops.
  ///
  /// If [stopId] is not currently saved, this is an idempotent no-op and returns immediately.
  /// Otherwise, updates in-memory state immediately, then asynchronously persists the snapshot.
  Future<void> unsaveStop(StopId stopId) async {
    final next = state.withoutStop(stopId);
    if (identical(next, state)) return;

    state = next;
    await _persist(next);
  }

  /// Saves [routeId].
  ///
  /// If [routeId] is already saved, this is an idempotent no-op and returns immediately.
  /// Otherwise, updates in-memory state immediately, then asynchronously persists the snapshot.
  Future<void> saveRoute(RouteId routeId) async {
    final next = state.withRoute(routeId);
    if (identical(next, state)) return;

    state = next;
    await _persist(next);
  }

  /// Removes [routeId] from saved routes.
  ///
  /// If [routeId] is not currently saved, this is an idempotent no-op and returns immediately.
  /// Otherwise, updates in-memory state immediately, then asynchronously persists the snapshot.
  Future<void> unsaveRoute(RouteId routeId) async {
    final next = state.withoutRoute(routeId);
    if (identical(next, state)) return;

    state = next;
    await _persist(next);
  }

  Future<void> _persist(SavedTransit snapshot) async {
    try {
      await ref.read(savedTransitRepositoryProvider).save(snapshot);
    } on StorageFailure catch (failure, st) {
      ref
          .read(appLoggerProvider)
          .warning(
            'SavedTransitController: failed to persist saved transit preferences',
            error: failure,
            stackTrace: st,
          );
      rethrow;
    }
  }
}

/// Application-wide provider for [SavedTransitController].
///
/// Not auto-disposed — lives for the lifetime of the [ProviderContainer].
final savedTransitControllerProvider =
    NotifierProvider<SavedTransitController, SavedTransit>(
      SavedTransitController.new,
      name: 'savedTransitControllerProvider',
    );
