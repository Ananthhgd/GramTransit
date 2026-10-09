import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/async_value_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/l10n/generated/app_localizations.dart';

/// Pumps [child] inside a localised [ProviderScope] for widget tests.
Future<void> pumpWidget(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('AsyncValueView', () {
    testWidgets('loading state shows GtLoadingView', (tester) async {
      await pumpWidget(
        tester,
        AsyncValueView<String>(
          value: const AsyncLoading(),
          data: (v) => Text(v),
        ),
      );
      expect(find.byType(GtLoadingView), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('data state shows data builder result', (tester) async {
      await pumpWidget(
        tester,
        AsyncValueView<String>(
          value: const AsyncData('hello'),
          data: (v) => Text(v),
        ),
      );
      expect(find.text('hello'), findsOneWidget);
      expect(find.byType(GtLoadingView), findsNothing);
    });

    testWidgets('AsyncError with StorageFailure shows storage error message', (
      tester,
    ) async {
      await pumpWidget(
        tester,
        AsyncValueView<String>(
          value: AsyncError(const StorageFailure(), StackTrace.empty),
          data: (v) => Text(v),
        ),
      );
      expect(find.byType(GtErrorView), findsOneWidget);
      // Check that the localized storage error string appears.
      expect(find.textContaining("couldn't save"), findsOneWidget);
    });

    testWidgets(
      'AsyncError with unknown error shows unexpected error message',
      (tester) async {
        await pumpWidget(
          tester,
          AsyncValueView<String>(
            value: AsyncError(Exception('boom'), StackTrace.empty),
            data: (v) => Text(v),
          ),
        );
        expect(find.byType(GtErrorView), findsOneWidget);
        expect(find.textContaining('Something went wrong'), findsOneWidget);
      },
    );

    testWidgets('retry callback is invoked when try-again button is tapped', (
      tester,
    ) async {
      var retryCalled = 0;
      await pumpWidget(
        tester,
        AsyncValueView<String>(
          value: AsyncError(const UnexpectedFailure(), StackTrace.empty),
          data: (v) => Text(v),
          onRetry: () => retryCalled++,
        ),
      );
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(retryCalled, equals(1));
    });

    testWidgets('no retry button when onRetry is null', (tester) async {
      await pumpWidget(
        tester,
        AsyncValueView<String>(
          value: AsyncError(const UnexpectedFailure(), StackTrace.empty),
          data: (v) => Text(v),
        ),
      );
      expect(find.text('Try again'), findsNothing);
    });

  });
}
