import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/app/router/app_router.dart';
import 'package:gramtransit_passenger/core/design_system/theme/gt_theme.dart';
import 'package:gramtransit_passenger/core/l10n/generated/app_localizations.dart';
import 'package:gramtransit_passenger/features/settings/application/theme_mode_controller.dart';

/// Root application widget.
///
/// Watches [themeModeControllerProvider] so theme changes apply immediately.
/// Obtains [routerProvider] once — the router does not rebuild on theme change.
class GramTransitApp extends ConsumerWidget {
  const GramTransitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'GramTransit',
      theme: GtTheme.light(),
      darkTheme: GtTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
