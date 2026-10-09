import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/error/app_failure_message.dart';
import 'package:gramtransit_passenger/core/l10n/generated/app_localizations.dart';

/// Pumps a minimal localised widget and returns the [AppLocalizations] instance.
Future<AppLocalizations> _pumpL10n(WidgetTester tester) async {
  late AppLocalizations l10n;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return l10n;
}

void main() {
  group('AppFailureMessage.of', () {
    testWidgets('StorageFailure maps to errorStorage string', (tester) async {
      final l10n = await _pumpL10n(tester);
      expect(
        AppFailureMessage.of(const StorageFailure(), l10n),
        equals(l10n.errorStorage),
      );
    });

    testWidgets('UnexpectedFailure maps to errorUnexpected string', (
      tester,
    ) async {
      final l10n = await _pumpL10n(tester);
      expect(
        AppFailureMessage.of(const UnexpectedFailure(), l10n),
        equals(l10n.errorUnexpected),
      );
    });

    testWidgets('All AppFailure subtypes map to non-empty strings', (
      tester,
    ) async {
      final l10n = await _pumpL10n(tester);
      for (final failure in <AppFailure>[
        const StorageFailure(),
        const UnexpectedFailure(),
      ]) {
        final message = AppFailureMessage.of(failure, l10n);
        expect(message, isNotEmpty, reason: '$failure mapped to empty string');
      }
    });
  });
}
