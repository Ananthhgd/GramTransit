import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/storage/key_value_store.dart';

/// In-memory [KeyValueStore] implementation.
///
/// Backed by a [Map<String, String>] — no platform I/O.
///
/// Use cases:
/// 1. Unit and widget tests — passed as a [keyValueStoreProvider] override.
/// 2. Runtime fallback when [SharedPreferences] initialisation fails at startup.
///
/// Reads and writes always succeed; the async write/remove interface is
/// fulfilled with [Future.value] to satisfy the interface contract.
final class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore({Map<String, String>? initial})
    : _store = initial != null ? Map.of(initial) : {};

  final Map<String, String> _store;

  @override
  String? getString(String key) => _store[key];

  @override
  Future<void> setString(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }
}

/// Creates a [StorageFailure] for use in tests that need to simulate a
/// failing store.
///
/// This is intentionally kept here (not in a separate test helper package) to
/// keep Foundation B self-contained.
final class FailingKeyValueStore implements KeyValueStore {
  const FailingKeyValueStore();

  @override
  String? getString(String key) => null;

  @override
  Future<void> setString(String key, String value) async {
    throw StorageFailure(
      cause: Exception('FailingKeyValueStore: setString always fails'),
    );
  }

  @override
  Future<void> remove(String key) async {
    throw StorageFailure(
      cause: Exception('FailingKeyValueStore: remove always fails'),
    );
  }
}
