import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/error/app_failure_message.dart';

import '../../helpers/widget_pump_helper.dart';

void main() {
  group('AppFailureMessage.of', () {
    testWidgets('StorageFailure maps to errorStorage string', (tester) async {
      final l10n = await pumpL10n(tester);
      expect(
        AppFailureMessage.of(const StorageFailure(), l10n),
        equals(l10n.errorStorage),
      );
    });

    testWidgets('DataFormatFailure maps to errorDataFormat string', (
      tester,
    ) async {
      final l10n = await pumpL10n(tester);
      expect(
        AppFailureMessage.of(const DataFormatFailure(), l10n),
        equals(l10n.errorDataFormat),
      );
    });

    testWidgets('UnexpectedFailure maps to errorUnexpected string', (
      tester,
    ) async {
      final l10n = await pumpL10n(tester);
      expect(
        AppFailureMessage.of(const UnexpectedFailure(), l10n),
        equals(l10n.errorUnexpected),
      );
    });

    testWidgets('All AppFailure subtypes map to non-empty strings', (
      tester,
    ) async {
      final l10n = await pumpL10n(tester);
      for (final failure in <AppFailure>[
        const StorageFailure(),
        const DataFormatFailure(),
        const UnexpectedFailure(),
      ]) {
        final message = AppFailureMessage.of(failure, l10n);
        expect(message, isNotEmpty, reason: '$failure mapped to empty string');
      }
    });
  });
}
