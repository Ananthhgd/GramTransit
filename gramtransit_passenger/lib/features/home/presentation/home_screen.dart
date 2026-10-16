import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/home_header.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/search_entry_placeholder.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/upcoming_departures_section.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';

/// Home screen — foundational layout only.
/// Search is coming soon; departures are backed by the schedule section.
///
/// Owns the session-only [selectedStopId] state for the Home screen (Model H-A).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StopId? _selectedStopId;

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
              const SearchEntryPlaceholder(),
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
