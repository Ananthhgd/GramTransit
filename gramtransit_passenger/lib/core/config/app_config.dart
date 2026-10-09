import 'package:gramtransit_passenger/core/config/app_environment.dart';

/// Immutable application configuration derived from compile-time dart-defines.
///
/// Instantiate via [AppConfig.fromEnvironment] at bootstrap, then expose it
/// through [appConfigProvider] so the rest of the application can read it.
///
/// No configuration values are displayed in the UI.
final class AppConfig {
  const AppConfig({required this.environment});

  /// The runtime environment the app is currently running in.
  final AppEnvironment environment;

  /// Reads the `APP_ENV` dart-define (defaulting to `'dev'`) and parses it
  /// into a typed [AppConfig].
  ///
  /// Throws a [StateError] immediately if the value is not a recognised
  /// environment name. This is intentional: a misconfigured build should fail
  /// loudly rather than running silently as an unexpected environment.
  factory AppConfig.fromEnvironment() {
    const rawEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final environment = AppEnvironment.parse(rawEnv);
    return AppConfig(environment: environment);
  }
}
