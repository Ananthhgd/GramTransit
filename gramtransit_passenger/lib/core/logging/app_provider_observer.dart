import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/logging/app_logger.dart';

/// Riverpod [ProviderObserver] that logs provider failures at warning level.
///
/// Only active in debug/profile builds — never registered in release.
/// Logs only when a provider emits an [AsyncError] state.
///
/// Low-noise by design:
/// - No add/dispose/update lifecycle events.
/// - No provider values, state contents, or preference data logged.
/// - Only the provider name and error type are logged; error objects must not
///   contain personal data (callers' responsibility).
final class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver(this._logger);

  final AppLogger _logger;

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    // Only log AsyncError states — ignore normal value updates.
    if (newValue is AsyncError) {
      _logger.warning(
        '[Provider] failure in provider — error: ${newValue.error.runtimeType}',
        error: newValue.error,
        stackTrace: newValue.stackTrace,
      );
    }
  }
}
