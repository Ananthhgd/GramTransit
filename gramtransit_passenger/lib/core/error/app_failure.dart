/// Minimal sealed failure hierarchy for the GramTransit Passenger application.
///
/// Rules:
/// - [AppFailure] subtypes contain diagnostic information only.
/// - No user-facing strings live here; localised messages belong in
///   [AppFailureMessage] (presentation layer).
/// - Infrastructure/repository boundaries translate platform/storage errors
///   into the appropriate subtype. [toAppFailure] exists only as a
///   last-resort defensive fallback for unclassified errors.
sealed class AppFailure {
  const AppFailure({this.cause, this.stackTrace});

  /// The underlying error that caused this failure, if available.
  final Object? cause;

  /// The stack trace associated with [cause], if available.
  final StackTrace? stackTrace;
}

/// A failure that occurred while reading from or writing to persistent storage.
final class StorageFailure extends AppFailure {
  const StorageFailure({super.cause, super.stackTrace});

  @override
  String toString() => 'StorageFailure(cause: $cause)';
}

/// A failure that does not fall into any other known category.
///
/// Indicates a programming error or a genuinely unexpected platform condition.
final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({super.cause, super.stackTrace});

  @override
  String toString() => 'UnexpectedFailure(cause: $cause)';
}

/// Defensive normaliser used only at unclassified error boundaries.
///
/// - If [error] is already an [AppFailure], returns it unchanged.
/// - Otherwise wraps it in an [UnexpectedFailure], preserving [cause] and
///   [stackTrace].
///
/// Infrastructure boundaries must translate known errors into typed subtypes
/// (e.g. [StorageFailure]) *before* propagating to the presentation layer.
AppFailure toAppFailure(Object error, StackTrace stackTrace) {
  if (error is AppFailure) return error;
  return UnexpectedFailure(cause: error, stackTrace: stackTrace);
}
