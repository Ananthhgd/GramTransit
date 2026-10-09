import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/core/config/app_environment.dart';

void main() {
  group('Environment files', () {
    test(
      'env directory contains exactly dev.json, staging.json, prod.json',
      () {
        final envDir = Directory('env');
        final files = envDir
            .listSync()
            .whereType<File>()
            .map((f) => f.uri.pathSegments.last)
            .toSet();

        expect(files, equals({'dev.json', 'staging.json', 'prod.json'}));
      },
    );

    test('each file parses as JSON and has exactly APP_ENV key', () {
      final envNames = ['dev', 'staging', 'prod'];
      for (final envName in envNames) {
        final file = File('env/$envName.json');
        final content = file.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;

        expect(json.keys.toSet(), equals({'APP_ENV'}));
        expect(json['APP_ENV'], equals(envName));

        // Verify it parses through AppEnvironment
        final parsedEnv = AppEnvironment.parse(json['APP_ENV'] as String);
        expect(parsedEnv.name, equals(envName));
      }
    });
  });
}
