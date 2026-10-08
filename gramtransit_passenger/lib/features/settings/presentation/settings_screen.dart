import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/settings/presentation/widgets/theme_mode_selector.dart';

/// Settings screen — Appearance section only in Foundation A.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: GtSpacing.sm),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GtSpacing.lg,
              GtSpacing.md,
              GtSpacing.lg,
              GtSpacing.xs,
            ),
            child: Text(
              l10n.settingsAppearanceSection,
              style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GtSpacing.lg,
              GtSpacing.sm,
              GtSpacing.lg,
              GtSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.settingsThemeLabel, style: textTheme.bodyMedium),
                const SizedBox(height: GtSpacing.sm),
                const ThemeModeSelector(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
