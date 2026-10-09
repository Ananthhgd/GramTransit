import 'package:shared_preferences/shared_preferences.dart';

import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/storage/key_value_store.dart';

/// [KeyValueStore] implementation backed by [SharedPreferencesWithCache].
///
/// [SharedPreferencesWithCache] maintains a synchronous in-memory cache loaded
/// at construction time, so [getString] is synchronous.
///
/// Write/remove failures from the underlying platform are translated into
/// [StorageFailure] at this boundary — callers receive a typed failure rather
/// than a raw platform exception.
final class SharedPreferencesKeyValueStore implements KeyValueStore {
  const SharedPreferencesKeyValueStore(this._prefs);

  final SharedPreferencesWithCache _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (e, st) {
      throw StorageFailure(cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _prefs.remove(key);
    } catch (e, st) {
      throw StorageFailure(cause: e, stackTrace: st);
    }
  }
}
