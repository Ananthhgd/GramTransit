import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/l10n/generated/app_localizations.dart';

/// Maps [AppFailure] subtypes exhaustively to localised user-facing messages.
///
/// Belongs to the presentation / localisation layer, not to the domain.
/// Keep this class small; resist adding logic beyond simple type → message mapping.
abstract final class AppFailureMessage {
  /// Returns a localised message string for [failure].
  ///
  /// The switch is exhaustive over the sealed [AppFailure] hierarchy so that
  /// a new subtype added without updating this class causes a compile-time error.
  static String of(AppFailure failure, AppLocalizations l10n) {
    return switch (failure) {
      StorageFailure() => l10n.errorStorage,
      DataFormatFailure() => l10n.errorDataFormat,
      UnexpectedFailure() => l10n.errorUnexpected,
    };
  }
}
