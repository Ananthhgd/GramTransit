import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/logging/app_logger.dart';

/// Application-wide [AppLogger] provider.
///
/// Bootstrap overrides this with the same logger instance it used during
/// startup so that the same logger is used throughout the entire app
/// lifecycle — before and after [runApp].
final appLoggerProvider = Provider<AppLogger>(
  (_) => const AppLogger(),
  name: 'appLoggerProvider',
);
