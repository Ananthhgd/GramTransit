import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/home_header.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/search_entry_placeholder.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/upcoming_departures_section.dart';

/// Home screen — foundational layout only.
/// Search is coming soon; departures are backed by the P5 schedule section.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: GtSpacing.lg,
            vertical: GtSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeHeader(),
              SizedBox(height: GtSpacing.xl),
              SearchEntryPlaceholder(),
              SizedBox(height: GtSpacing.xl),
              UpcomingDeparturesSection(),
            ],
          ),
        ),
      ),
    );
  }
}
