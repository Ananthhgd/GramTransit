import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';

/// Persistent application shell that hosts the [NavigationBar] and delegates
/// page rendering to the active [StatefulNavigationShell] branch.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Re-selecting the active tab returns to the branch's initial location.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: context.l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view),
            label: context.l10n.navMore,
          ),
        ],
      ),
    );
  }
}
