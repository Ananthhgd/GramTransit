import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/core/config/app_config.dart';
import 'package:gramtransit_passenger/core/config/app_environment.dart';

void main() {
  test('compile-time dart-define AppConfig environment verification', () {
    const expectedEnvString = String.fromEnvironment('EXPECTED_APP_ENV');

    if (expectedEnvString.isEmpty) {
      // Skip or no-op when not explicitly provided
      return;
    }

    final expectedEnv = AppEnvironment.parse(expectedEnvString);
    final config = AppConfig.fromEnvironment();

    expect(config.environment, equals(expectedEnv));
  });
}
