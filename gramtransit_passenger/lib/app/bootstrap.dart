import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gramtransit_passenger/app/gramtransit_app.dart';
import 'package:gramtransit_passenger/core/config/app_config.dart';
import 'package:gramtransit_passenger/core/config/config_providers.dart';
import 'package:gramtransit_passenger/core/logging/app_logger.dart';
import 'package:gramtransit_passenger/core/logging/app_provider_observer.dart';
import 'package:gramtransit_passenger/core/logging/logging_providers.dart';
import 'package:gramtransit_passenger/core/storage/in_memory_key_value_store.dart';
import 'package:gramtransit_passenger/core/storage/key_value_store.dart';
import 'package:gramtransit_passenger/core/storage/shared_preferences_key_value_store.dart';
import 'package:gramtransit_passenger/core/storage/storage_providers.dart';

/// Initialises all platform resources and launches the application.
///
/// Sequence:
/// 1. Ensure Flutter bindings are initialised.
/// 2. Parse typed [AppConfig] from compile-time dart-defines (fails fast on
///    invalid environment).
/// 3. Create [AppLogger].
/// 4. Install a lightweight global error logger that preserves Flutter's normal
///    debug error presentation.
/// 5. Initialise [SharedPreferencesWithCache]. On failure, fall back to
///    [InMemoryKeyValueStore] so the app can still run without persistence.
/// 6. Build [ProviderContainer] with concrete overrides.
/// 7. Register [AppProviderObserver] in debug/profile builds only.
/// 8. Log a safe startup event (environment name only — no preference values).
/// 9. Run the app using [UncontrolledProviderScope].
Future<void> bootstrap() async {
  // ─── 1. Flutter bindings ───────────────────────────────────────────────────
  WidgetsFlutterBinding.ensureInitialized();

  // ─── 2. Typed config (fails fast on invalid APP_ENV) ──────────────────────
  final config = AppConfig.fromEnvironment();

  // ─── 3. Logger ────────────────────────────────────────────────────────────
  const logger = AppLogger();

  // ─── 4. Global Flutter error logging ──────────────────────────────────────
  // Wrap the existing handler to add logging without suppressing it.
  // In debug mode, Flutter's default red-screen presentation is preserved.
  final previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.error(
      'FlutterError: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
    // Preserve existing handler (e.g. FlutterError.presentError in debug).
    previousFlutterErrorHandler?.call(details);
  };

  // ─── 5. Storage initialisation ────────────────────────────────────────────
  final keyValueStore = await _initStorage(logger);

  // ─── 6 + 7. ProviderContainer with overrides ──────────────────────────────
  final observers = <ProviderObserver>[
    // Only register the failure observer in debug/profile builds.
    if (!kReleaseMode) AppProviderObserver(logger),
  ];

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      appLoggerProvider.overrideWithValue(logger),
      keyValueStoreProvider.overrideWithValue(keyValueStore),
    ],
    observers: observers,
  );

  // ─── 8. Safe startup log ──────────────────────────────────────────────────
  logger.info('GramTransit starting — env: ${config.environment.name}');

  // ─── 9. Run app ───────────────────────────────────────────────────────────
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const GramTransitApp(),
    ),
  );
}

/// Attempts to initialise [SharedPreferencesKeyValueStore].
///
/// On failure, logs a safe warning (no preference values) and returns
/// [InMemoryKeyValueStore] so the app can launch without persistence.
Future<KeyValueStore> _initStorage(AppLogger logger) async {
  try {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    return SharedPreferencesKeyValueStore(prefs);
  } catch (e, st) {
    logger.warning(
      'SharedPreferences init failed — falling back to in-memory store',
      error: e,
      stackTrace: st,
    );
    return InMemoryKeyValueStore();
  }
}
