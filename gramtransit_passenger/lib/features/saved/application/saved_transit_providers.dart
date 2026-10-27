import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/logging/logging_providers.dart';
import 'package:gramtransit_passenger/core/storage/storage_providers.dart';
import 'package:gramtransit_passenger/features/saved/data/saved_transit_repository.dart';

/// Application-wide provider for [SavedTransitRepository].
///
/// Injected with [keyValueStoreProvider] and [appLoggerProvider].
final savedTransitRepositoryProvider = Provider<SavedTransitRepository>(
  (ref) => SavedTransitRepository(
    ref.watch(keyValueStoreProvider),
    logger: ref.watch(appLoggerProvider),
  ),
  name: 'savedTransitRepositoryProvider',
);
