import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gramtransit_passenger/app/router/app_routes.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';

/// More screen — entry point for secondary application features.
/// Foundation A exposes only the Settings entry.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.moreSettings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.goNamed(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}
