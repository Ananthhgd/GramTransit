import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/config/app_config.dart';

/// Application-wide [AppConfig] provider.
///
/// The default implementation uses [AppConfig.fromEnvironment] so that
/// tests and bootstrap can override it with a pre-built instance without
/// re-parsing dart-defines.
///
/// Bootstrap MUST override this with the instance it created so the same
/// object is used throughout the lifetime of the [ProviderContainer].
final appConfigProvider = Provider<AppConfig>(
  (_) => AppConfig.fromEnvironment(),
  name: 'appConfigProvider',
);
