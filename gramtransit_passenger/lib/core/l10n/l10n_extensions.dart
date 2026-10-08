import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/l10n/generated/app_localizations.dart';

/// Convenience extension that exposes [AppLocalizations] from [BuildContext].
///
/// Usage: `context.l10n.appTitle`
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
