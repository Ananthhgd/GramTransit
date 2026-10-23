import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';

/// Explore entry area on the Home screen providing direct navigation to
/// All stops and All routes.
class HomeExploreSection extends StatelessWidget {
  const HomeExploreSection({
    super.key,
    required this.onAllStopsTap,
    required this.onAllRoutesTap,
  });

  /// Callback invoked when the "All stops" card is tapped.
  final VoidCallback onAllStopsTap;

  /// Callback invoked when the "All routes" card is tapped.
  final VoidCallback onAllRoutesTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.homeExploreTitle,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: GtSpacing.xs),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ExploreActionCard(
                  icon: Icons.place_outlined,
                  label: l10n.homeExploreAllStops,
                  onTap: onAllStopsTap,
                ),
              ),
              const SizedBox(width: GtSpacing.md),
              Expanded(
                child: _ExploreActionCard(
                  icon: Icons.directions_bus_outlined,
                  label: l10n.homeExploreAllRoutes,
                  onTap: onAllRoutesTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExploreActionCard extends StatelessWidget {
  const _ExploreActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: label,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GtSpacing.md,
                vertical: GtSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 24, color: colorScheme.primary),
                  const SizedBox(width: GtSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
