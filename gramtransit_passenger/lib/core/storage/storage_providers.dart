import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/storage/key_value_store.dart';

/// Application-wide [KeyValueStore] provider.
///
/// The default body throws [UnimplementedError] to make misconfiguration
/// immediately obvious: the bootstrap function MUST override this provider
/// with a concrete implementation before [runApp] is called.
///
/// In tests, override with [InMemoryKeyValueStore] via a [ProviderScope]
/// or [ProviderContainer] override.
final keyValueStoreProvider = Provider<KeyValueStore>(
  (_) => throw UnimplementedError(
    'keyValueStoreProvider has not been initialised. '
    'Ensure bootstrap() overrides it with a concrete KeyValueStore '
    'before runApp() is called, or provide an override in your test.',
  ),
  name: 'keyValueStoreProvider',
);
