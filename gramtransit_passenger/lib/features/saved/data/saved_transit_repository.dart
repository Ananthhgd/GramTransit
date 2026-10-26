import 'package:gramtransit_passenger/core/logging/app_logger.dart';
import 'package:gramtransit_passenger/core/storage/key_value_store.dart';
import 'package:gramtransit_passenger/features/saved/data/saved_transit_codec.dart';
import 'package:gramtransit_passenger/features/saved/domain/saved_transit.dart';

/// Storage key for persisted saved transit preferences.
///
/// Owned by the saved feature. Kept as a private constant to prevent
/// accidental external coupling.
const _kSavedTransitKey = 'gt.saved.transit';

/// Manages reading and writing saved transit preferences to [KeyValueStore].
///
/// Delegates serialization and tolerant deserialization to [SavedTransitCodec].
/// Does not mutate storage on read or decode failures.
/// Propagates [StorageFailure] directly from [KeyValueStore] on save.
final class SavedTransitRepository {
  SavedTransitRepository(
    this._store, {
    AppLogger logger = const AppLogger(),
    SavedTransitCodec? codec,
  }) : _codec = codec ?? SavedTransitCodec(logger: logger);

  final KeyValueStore _store;
  final SavedTransitCodec _codec;

  /// Synchronously reads the persisted [SavedTransit].
  ///
  /// Returns an empty [SavedTransit] if the storage key is missing or if the
  /// stored data is malformed. Never throws.
  SavedTransit read() {
    final rawJson = _store.getString(_kSavedTransitKey);
    return _codec.decode(rawJson);
  }

  /// Asynchronously persists [savedTransit] as version 1 JSON.
  ///
  /// Writes to a single key and preserves list order. Empty states are
  /// persisted as valid version 1 JSON with empty stop and route arrays.
  ///
  /// Throws [StorageFailure] if the write cannot be completed.
  Future<void> save(SavedTransit savedTransit) {
    final encoded = _codec.encode(savedTransit);
    return _store.setString(_kSavedTransitKey, encoded);
  }
}
