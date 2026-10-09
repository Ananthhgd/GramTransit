/// Abstract key-value storage contract used by GramTransit infrastructure.
///
/// Exposes only the operations consumed by Foundation B.
/// Additional typed accessors (bool, int, double, JSON) are NOT included —
/// add them only when a genuine consumer exists.
///
/// Key convention: `gt.<feature>.<name>`
/// Example: `gt.settings.theme_mode`
///
/// Keys belong to the owning feature, not to [core].
abstract interface class KeyValueStore {
  /// Returns the stored string for [key], or `null` if absent.
  ///
  /// Reads are synchronous because implementations maintain an in-memory cache.
  String? getString(String key);

  /// Persists [value] for [key].
  ///
  /// Throws a [StorageFailure] if the write cannot be completed.
  Future<void> setString(String key, String value);

  /// Removes the entry for [key].
  ///
  /// Is a no-op if [key] does not exist.
  /// Throws a [StorageFailure] if the removal cannot be completed.
  Future<void> remove(String key);
}
