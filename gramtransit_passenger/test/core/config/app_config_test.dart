import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/config/app_config.dart';
import 'package:gramtransit_passenger/core/config/app_environment.dart';

void main() {
  group('AppEnvironment.parse', () {
    test('parses "dev" successfully', () {
      expect(AppEnvironment.parse('dev'), AppEnvironment.dev);
    });

    test('parses "staging" successfully', () {
      expect(AppEnvironment.parse('staging'), AppEnvironment.staging);
    });

    test('parses "prod" successfully', () {
      expect(AppEnvironment.parse('prod'), AppEnvironment.prod);
    });

    test('throws StateError for empty string', () {
      expect(
        () => AppEnvironment.parse(''),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Invalid APP_ENV value'),
          ),
        ),
      );
    });

    test('throws StateError for uppercase "DEV"', () {
      expect(() => AppEnvironment.parse('DEV'), throwsA(isA<StateError>()));
    });

    test(
      'throws StateError for unknown value, message identifies the value',
      () {
        expect(
          () => AppEnvironment.parse('production'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              allOf(contains('production'), contains('dev, staging, prod')),
            ),
          ),
        );
      },
    );
  });

  group('AppConfig', () {
    test('fromEnvironment defaults to dev when APP_ENV is not set', () {
      // In tests, dart-defines are not set so the default 'dev' applies.
      final config = AppConfig.fromEnvironment();
      expect(config.environment, AppEnvironment.dev);
    });

    test('accepts explicit AppEnvironment via constructor', () {
      const config = AppConfig(environment: AppEnvironment.staging);
      expect(config.environment, AppEnvironment.staging);
    });
  });
}
