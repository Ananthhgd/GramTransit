import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gramtransit_passenger/app/router/app_routes.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_empty_state.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/error/app_failure_message.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';
import 'package:gramtransit_passenger/features/trip_details/application/trip_details_provider.dart';
import 'package:gramtransit_passenger/features/trip_details/presentation/widgets/trip_header.dart';
import 'package:gramtransit_passenger/features/trip_details/presentation/widgets/trip_scheduled_times_note.dart';
import 'package:gramtransit_passenger/features/trip_details/presentation/widgets/trip_stop_list.dart';

/// Full-screen Trip Details screen displaying route details and scheduled stop times.
class TripDetailsScreen extends ConsumerWidget {
  const TripDetailsScreen({super.key, this.tripId});

  /// The trip identifier to display.
  /// If null (e.g. unparseable route parameter), the screen shows the trip-not-found state.
  final TripId? tripId;

  String _resolveErrorMessage(Object error, BuildContext context) {
    if (error is AppFailure) {
      return AppFailureMessage.of(error, context.l10n);
    }
    return context.l10n.errorUnexpected;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    final effectiveTripId = tripId;
    if (effectiveTripId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tripDetailsTitle)),
        body: SafeArea(
          child: GtEmptyState(
            icon: Icons.directions_bus_outlined,
            title: l10n.tripNotFoundTitle,
            message: l10n.tripNotFoundMessage,
            actionLabel: l10n.tripNotFoundAction,
            onAction: () => context.goNamed(AppRoutes.home),
          ),
        ),
      );
    }

    final tripAsync = ref.watch(tripDetailsProvider(effectiveTripId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripDetailsTitle)),
      body: SafeArea(
        child: tripAsync.when(
          loading: () => const GtLoadingView(),
          error: (error, _) => GtErrorView(
            message: _resolveErrorMessage(error, context),
            onRetry: () => ref.refresh(timetableProvider),
          ),
          data: (details) {
            if (details == null) {
              return GtEmptyState(
                icon: Icons.directions_bus_outlined,
                title: l10n.tripNotFoundTitle,
                message: l10n.tripNotFoundMessage,
                actionLabel: l10n.tripNotFoundAction,
                onAction: () => context.goNamed(AppRoutes.home),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(GtSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TripHeader(details: details),
                  const SizedBox(height: GtSpacing.md),
                  const TripScheduledTimesNote(),
                  const SizedBox(height: GtSpacing.lg),
                  Text(
                    l10n.tripDetailsStopTimesTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: GtSpacing.md),
                  TripStopList(stops: details.stops),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
