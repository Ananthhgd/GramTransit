import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/design_system/theme/gt_theme.dart';
import 'package:gramtransit_passenger/core/l10n/generated/app_localizations.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/home_explore_section.dart';

void main() {
  Widget buildTestWidget({
    VoidCallback? onAllStopsTap,
    VoidCallback? onAllRoutesTap,
    ThemeMode themeMode = ThemeMode.light,
    double textScaleFactor = 1.0,
    Size surfaceSize = const Size(360, 640),
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: GtTheme.light(),
      darkTheme: GtTheme.dark(),
      themeMode: themeMode,
      home: MediaQuery(
        data: MediaQueryData(
          size: surfaceSize,
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: HomeExploreSection(
              onAllStopsTap: onAllStopsTap ?? () {},
              onAllRoutesTap: onAllRoutesTap ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  group('HomeExploreSection', () {
    testWidgets('1. renders Explore title, All stops, and All routes actions', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('All stops'), findsOneWidget);
      expect(find.text('All routes'), findsOneWidget);
      expect(find.byIcon(Icons.place_outlined), findsOneWidget);
      expect(find.byIcon(Icons.directions_bus_outlined), findsOneWidget);
    });

    testWidgets('2. tapping All stops invokes onAllStopsTap callback', (
      tester,
    ) async {
      var stopsTapped = false;

      await tester.pumpWidget(
        buildTestWidget(onAllStopsTap: () => stopsTapped = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('All stops'));
      await tester.pumpAndSettle();

      expect(stopsTapped, isTrue);
    });

    testWidgets('3. tapping All routes invokes onAllRoutesTap callback', (
      tester,
    ) async {
      var routesTapped = false;

      await tester.pumpWidget(
        buildTestWidget(onAllRoutesTap: () => routesTapped = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('All routes'));
      await tester.pumpAndSettle();

      expect(routesTapped, isTrue);
    });

    testWidgets(
      '4. provides minimum 48dp interactive target height and semantics',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final stopsInkWell = find.ancestor(
          of: find.text('All stops'),
          matching: find.byType(InkWell),
        );
        final routesInkWell = find.ancestor(
          of: find.text('All routes'),
          matching: find.byType(InkWell),
        );

        final stopsSize = tester.getSize(stopsInkWell);
        final routesSize = tester.getSize(routesInkWell);

        expect(stopsSize.height, greaterThanOrEqualTo(48.0));
        expect(stopsSize.width, greaterThanOrEqualTo(48.0));
        expect(routesSize.height, greaterThanOrEqualTo(48.0));
        expect(routesSize.width, greaterThanOrEqualTo(48.0));

        // Semantics checks
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.button == true &&
                w.properties.label == 'All stops',
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.button == true &&
                w.properties.label == 'All routes',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('5. 200% text scale on 360dp width renders without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestWidget(
          textScaleFactor: 2.0,
          surfaceSize: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('All stops'), findsOneWidget);
      expect(find.text('All routes'), findsOneWidget);
    });

    testWidgets('6. light and dark theme compatibility', (tester) async {
      // Light theme
      await tester.pumpWidget(buildTestWidget(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Dark theme
      await tester.pumpWidget(buildTestWidget(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
