import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/error/app_failure_message.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';

/// Maps an [AsyncValue<T>] to appropriate UI.
///
/// Behaviour:
/// - Loading without previous value → [GtLoadingView].
/// - Error without previous value → [GtErrorView] with localised message.
/// - Data (including stale data during refresh) → [data] builder.
///
/// When [AsyncValue] carries previous/stale data alongside a loading or error
/// state (i.e. [AsyncValue.isRefreshing] or [AsyncValue.isReloading]), the
/// previous data is shown to avoid content disappearing during a refresh.
///
/// Failure localisation:
/// - [AppFailure] subtypes → [AppFailureMessage.of].
/// - Unknown errors → [toAppFailure] → [UnexpectedFailure] → localised message.
///
/// Empty-state handling is NOT this widget's responsibility — handle it in the
/// [data] builder.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  String _resolveErrorMessage(Object error, BuildContext context) {
    final l10n = context.l10n;
    // Normalise unknown errors defensively before looking up the message.
    final failure = error is AppFailure
        ? error
        : toAppFailure(error, StackTrace.current);
    return AppFailureMessage.of(failure, l10n);
  }

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: data,
      loading: () => const GtLoadingView(),
      error: (error, _) => GtErrorView(
        message: _resolveErrorMessage(error, context),
        onRetry: onRetry,
      ),
    );
  }
}
