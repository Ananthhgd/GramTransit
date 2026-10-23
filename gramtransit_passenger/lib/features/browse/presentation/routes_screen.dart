import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_empty_state.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/error/app_failure_message.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/browse/presentation/browse_display_format.dart';
import 'package:gramtransit_passenger/features/browse/presentation/widgets/browse_sample_data_notice.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

/// Screen listing all canonical routes in the loaded timetable.
///
/// Pure presentation component representing the future `/routes` path.
/// Does not perform internal navigation; exposes [onRouteTap] callback.
class RoutesScreen extends ConsumerWidget {
  const RoutesScreen({super.key, this.onRouteTap});

  /// Optional callback invoked when a route row is tapped.
  /// Passes the canonical [RouteId].
  final ValueChanged<RouteId>? onRouteTap;

  static String _resolveErrorMessage(Object error, BuildContext context) {
    if (error is AppFailure) {
      return AppFailureMessage.of(error, context.l10n);
    }
    return context.l10n.homeTimetableLoadError;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final timetableAsync = ref.watch(timetableProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.routesTitle)),
      body: SafeArea(
        child: timetableAsync.when(
          loading: () => const GtLoadingView(),
          error: (error, _) => GtErrorView(
            message: _resolveErrorMessage(error, context),
            onRetry: () => ref.refresh(timetableProvider),
          ),
          data: (timetable) {
            if (timetable.routes.isEmpty) {
              return GtEmptyState(
                icon: Icons.directions_bus_outlined,
                title: l10n.routesNoRoutesAvailable,
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: GtSpacing.md),
              child: Column(
                children: [
                  const SizedBox(height: GtSpacing.sm),
                  if (timetable.info.isSampleData) ...[
                    const BrowseSampleDataNotice(compact: true),
                    const SizedBox(height: GtSpacing.sm),
                  ],
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: GtSpacing.sm,
                      ),
                      itemCount: timetable.routes.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: GtSpacing.sm),
                      itemBuilder: (context, index) {
                        final route = timetable.routes[index];
                        return _buildRouteRow(context, route);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRouteRow(BuildContext context, TransitRoute route) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final shortName = resolveLocalizedText(route.shortName, context);
    final longName = resolveLocalizedText(route.longName, context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onRouteTap != null ? () => onRouteTap!(route.id) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GtSpacing.md,
              vertical: GtSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GtSpacing.sm,
                    vertical: GtSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    shortName,
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: GtSpacing.md),
                Expanded(
                  child: Text(
                    longName,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: GtSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
