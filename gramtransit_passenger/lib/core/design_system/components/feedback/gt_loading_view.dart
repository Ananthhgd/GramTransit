import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';

/// A centered [CircularProgressIndicator] with a screen-reader-accessible
/// semantic label.
///
/// Use this widget whenever async content is loading and no previous data
/// is available to display in its place.
class GtLoadingView extends StatelessWidget {
  const GtLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: context.l10n.loadingLabel,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}
