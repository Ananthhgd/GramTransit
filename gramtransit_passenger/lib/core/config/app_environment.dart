/// Typed representation of the application runtime environment.
///
/// The value is read at compile time via [AppConfig.fromEnvironment] using
/// the `APP_ENV` dart-define key. Invalid values fail fast with a [StateError].
enum AppEnvironment {
  dev,
  staging,
  prod;

  /// Parses [value] (case-sensitive, exact lowercase match) into an
  /// [AppEnvironment].
  ///
  /// Throws a [StateError] if [value] is not one of the allowed values,
  /// making misconfiguration immediately visible at startup rather than
  /// silently defaulting or misbehaving at runtime.
  static AppEnvironment parse(String value) {
    return switch (value) {
      'dev' => AppEnvironment.dev,
      'staging' => AppEnvironment.staging,
      'prod' => AppEnvironment.prod,
      _ => throw StateError(
        'Invalid APP_ENV value: "$value". '
        'Allowed values are: dev, staging, prod.',
      ),
    };
  }
}
