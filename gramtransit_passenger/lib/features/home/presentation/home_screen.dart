import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gramtransit_passenger/app/router/app_routes.dart';
import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/home_header.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/search_entry_placeholder.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/upcoming_departures_section.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';

/// Home screen — foundational layout only.
///
/// Owns the session-only [selectedStopId] state for the Home screen (Model H-A).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, @visibleForTesting this.onSearchTap});

  /// Optional test injection callback invoked when the search entry is tapped.
  ///
  /// If null, standard [GoRouter] navigation via [context.pushNamed] is used.
  final ValueChanged<StopId?>? onSearchTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StopId? _selectedStopId;

  void _onSearchTapped() {
    if (widget.onSearchTap != null) {
      widget.onSearchTap!(_selectedStopId);
      return;
    }
    final stopId = _selectedStopId;
    if (stopId != null) {
      context.pushNamed(
        AppRoutes.journeys,
        queryParameters: {'from': stopId.value},
      );
    } else {
      context.pushNamed(AppRoutes.journeys);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: GtSpacing.lg,
            vertical: GtSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HomeHeader(),
              const SizedBox(height: GtSpacing.xl),
              SearchEntryPlaceholder(onTap: _onSearchTapped),
              const SizedBox(height: GtSpacing.xl),
              UpcomingDeparturesSection(
                selectedStopId: _selectedStopId,
                onStopSelected: (stopId) {
                  setState(() {
                    _selectedStopId = stopId;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
