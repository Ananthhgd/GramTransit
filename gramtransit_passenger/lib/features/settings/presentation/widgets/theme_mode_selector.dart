import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/settings/application/theme_mode_controller.dart';

/// Material 3 [SegmentedButton] that toggles between
/// [ThemeMode.system], [ThemeMode.light], and [ThemeMode.dark].
///
/// Changes apply immediately via [ThemeModeController].
/// Nothing is persisted — restarting returns to [ThemeMode.system].
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeControllerProvider);
    final l10n = context.l10n;

    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment<ThemeMode>(
          value: ThemeMode.system,
          icon: const Icon(Icons.brightness_auto_outlined),
          label: Text(l10n.themeModeSystem),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.light,
          icon: const Icon(Icons.light_mode_outlined),
          label: Text(l10n.themeModeLight),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.dark,
          icon: const Icon(Icons.dark_mode_outlined),
          label: Text(l10n.themeModeDark),
        ),
      ],
      selected: {currentMode},
      onSelectionChanged: (selection) {
        ref
            .read(themeModeControllerProvider.notifier)
            .setThemeMode(selection.first);
      },
    );
  }
}
