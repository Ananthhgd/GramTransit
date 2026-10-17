import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/error/app_failure_message.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/widgets/journey_results_section.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/widgets/journey_sample_data_notice.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/widgets/journey_scheduled_times_note.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/widgets/journey_stop_selector.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/scheduled_journey.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

/// Screen for searching direct scheduled journeys between a boarding stop
/// and an alighting stop.
class JourneySearchScreen extends ConsumerStatefulWidget {
  const JourneySearchScreen({
    super.key,
    this.initialBoardingStopId,
    this.initialAlightingStopId,
    this.onJourneySelected,
  });

  /// Optional initial boarding stop ID (e.g. passed from Home or route).
  final StopId? initialBoardingStopId;

  /// Optional initial alighting stop ID (e.g. passed from route query).
  final StopId? initialAlightingStopId;

  /// Optional callback invoked when a journey card is tapped.
  final ValueChanged<ScheduledJourney>? onJourneySelected;

  @override
  ConsumerState<JourneySearchScreen> createState() =>
      _JourneySearchScreenState();
}

class _JourneySearchScreenState extends ConsumerState<JourneySearchScreen> {
  StopId? _boardingStopId;
  StopId? _alightingStopId;
  bool _didSanitizeInitialQuery = false;

  @override
  void initState() {
    super.initState();
    _boardingStopId = widget.initialBoardingStopId;
    _alightingStopId = widget.initialAlightingStopId;
  }

  void _onBoardingStopSelected(StopId? stopId) {
    setState(() {
      _boardingStopId = stopId;
      if (_alightingStopId != null && _alightingStopId == stopId) {
        _alightingStopId = null;
      }
    });
  }

  void _onAlightingStopSelected(StopId? stopId) {
    setState(() {
      _alightingStopId = stopId;
    });
  }

  void _swapStops(StopId? effectiveFrom, StopId? effectiveTo) {
    if (effectiveFrom != null && effectiveTo != null) {
      setState(() {
        _boardingStopId = effectiveTo;
        _alightingStopId = effectiveFrom;
      });
    } else if (effectiveFrom != null && effectiveTo == null) {
      setState(() {
        _boardingStopId = null;
        _alightingStopId = effectiveFrom;
      });
    } else if (effectiveFrom == null && effectiveTo != null) {
      setState(() {
        _boardingStopId = effectiveTo;
        _alightingStopId = null;
      });
    }
  }

  static String _resolveErrorMessage(Object error, BuildContext context) {
    if (error is AppFailure) {
      return AppFailureMessage.of(error, context.l10n);
    }
    return context.l10n.homeTimetableLoadError;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final timetableAsync = ref.watch(timetableProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.journeySearchTitle)),
      body: SafeArea(
        child: timetableAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: GtSpacing.xl),
            child: GtLoadingView(),
          ),
          error: (error, _) => GtErrorView(
            message: _resolveErrorMessage(error, context),
            onRetry: () => ref.refresh(timetableProvider),
          ),
          data: (timetable) {
            // Stage 2: One-time timetable-aware semantic sanitization of initial query
            if (!_didSanitizeInitialQuery) {
              _didSanitizeInitialQuery = true;
              final isFromKnown =
                  _boardingStopId != null &&
                  timetable.stops.any((s) => s.id == _boardingStopId);
              final isToKnown =
                  _alightingStopId != null &&
                  timetable.stops.any((s) => s.id == _alightingStopId);

              if (!isFromKnown) {
                _boardingStopId = null;
              }
              if (!isToKnown) {
                _alightingStopId = null;
              }
              if (_boardingStopId != null &&
                  _alightingStopId != null &&
                  _boardingStopId == _alightingStopId) {
                _alightingStopId = null;
              }
            }

            final effectiveFrom = _boardingStopId;
            final effectiveTo = _alightingStopId;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: GtSpacing.lg,
                vertical: GtSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const JourneyScheduledTimesNote(),
                  if (timetable.info.isSampleData) ...[
                    const SizedBox(height: GtSpacing.sm),
                    const JourneySampleDataNotice(),
                  ],
                  const SizedBox(height: GtSpacing.md),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(GtSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          JourneyStopSelector(
                            label: l10n.journeySearchFromLabel,
                            hintText: l10n.journeySearchFromPlaceholder,
                            selectedStopId: effectiveFrom,
                            excludedStopId: null,
                            onStopSelected: _onBoardingStopSelected,
                          ),
                          const SizedBox(height: GtSpacing.sm),
                          Center(
                            child: IconButton(
                              icon: const Icon(Icons.swap_vert_rounded),
                              tooltip: l10n.journeySearchSwapStops,
                              onPressed: () =>
                                  _swapStops(effectiveFrom, effectiveTo),
                            ),
                          ),
                          const SizedBox(height: GtSpacing.sm),
                          JourneyStopSelector(
                            label: l10n.journeySearchToLabel,
                            hintText: l10n.journeySearchToPlaceholder,
                            selectedStopId: effectiveTo,
                            excludedStopId: effectiveFrom,
                            onStopSelected: _onAlightingStopSelected,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: GtSpacing.lg),
                  JourneyResultsSection(
                    boardingStopId: effectiveFrom,
                    alightingStopId: effectiveTo,
                    onJourneySelected: widget.onJourneySelected,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
