import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architecture Guardrails', () {
    final libDir = Directory('lib');
    late List<File> allDartFiles;

    setUpAll(() {
      allDartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
    });

    test('G1: lib/core must not import lib/app or lib/features', () {
      final coreFiles = allDartFiles.where(
        (f) => f.path.replaceAll('\\', '/').contains('/core/'),
      );
      for (final file in coreFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.startsWith('import ')) {
            if (line.contains('/app/') || line.contains('/features/')) {
              fail('G1 Violation in ${file.path}:${i + 1}\n$line');
            }
          }
        }
      }
    });

    test('G2/G3: presentation must not import data layer; features must not import other feature data/presentation internals', () {
      final featureFiles = allDartFiles.where(
        (f) => f.path.replaceAll('\\', '/').contains('/features/'),
      );
      for (final file in featureFiles) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        final parts = normalizedPath.split('/features/');
        if (parts.length > 1) {
          final featureRest = parts[1].split('/');
          final featureName = featureRest.first;
          final isPresentation = normalizedPath.contains(
            '/features/$featureName/presentation/',
          );

          final content = file.readAsStringSync();
          final lines = content.split('\n');
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.startsWith('import ')) {
              if (isPresentation && line.contains('/data/')) {
                fail('G2 Violation in ${file.path}:${i + 1}\n$line');
              }
              if (line.contains('/features/')) {
                final targetMatch = RegExp(
                  r'/features/([^/]+)/(data|presentation)/',
                ).firstMatch(line);
                if (targetMatch != null) {
                  final targetFeature = targetMatch.group(1);
                  if (targetFeature != featureName) {
                    fail('G3 Violation in ${file.path}:${i + 1}\n$line');
                  }
                }
              }
            }
          }
        }
      }
    });

    test('G4: lib/features/**/domain must not depend on Flutter framework', () {
      final domainFiles = allDartFiles.where(
        (f) => f.path.replaceAll('\\', '/').contains('/domain/'),
      );
      for (final file in domainFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.startsWith('import ') && line.contains('package:flutter/')) {
            fail('G4 Violation in ${file.path}:${i + 1}\n$line');
          }
        }
      }
    });

    test('G5: package:shared_preferences may be imported only by the approved adapter', () {
      for (final file in allDartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.startsWith('import ') &&
              line.contains('package:shared_preferences')) {
            final normalizedPath = file.path.replaceAll('\\', '/');
            if (!normalizedPath.endsWith(
                  'lib/core/storage/shared_preferences_key_value_store.dart',
                ) &&
                !normalizedPath.endsWith('lib/app/bootstrap.dart')) {
              fail('G5 Violation in ${file.path}:${i + 1}\n$line');
            }
          }
        }
      }
    });

    test(
      'G6: Environment parsing must remain centralized under lib/core/config/',
      () {
        for (final file in allDartFiles) {
          final normalizedPath = file.path.replaceAll('\\', '/');
          final content = file.readAsStringSync();
          final lines = content.split('\n');
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.contains('String.fromEnvironment(') ||
                line.contains('bool.fromEnvironment(') ||
                line.contains('int.fromEnvironment(')) {
              if (!normalizedPath.contains('lib/core/config/')) {
                fail('G6 Violation in ${file.path}:${i + 1}\n$line');
              }
            }
          }
        }
      },
    );

    test('G7: debugPrint must not appear in production lib code', () {
      for (final file in allDartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains('debugPrint(')) {
            fail('G7 Violation in ${file.path}:${i + 1}\n$line');
          }
        }
      }
    });
  });
}
