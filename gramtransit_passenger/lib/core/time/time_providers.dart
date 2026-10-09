import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/time/clock.dart';

/// Application-wide [Clock] provider.
///
/// Overridden in tests to provide a deterministic time.
final clockProvider = Provider<Clock>(
  (_) => const SystemClock(),
  name: 'clockProvider',
);

/// A feature-agnostic ticker that yields the current time exactly on minute boundaries.
///
/// Used to trigger UI or provider refreshes (e.g., upcoming departures) when
/// the wall-clock minute changes.
///
/// In tests, override this provider with a mock stream to simulate time progression
/// without wall-clock delays.
final minuteTickerProvider = StreamProvider.autoDispose<DateTime>(
  (ref) {
    final clock = ref.watch(clockProvider);
    final controller = StreamController<DateTime>(sync: true);
    Timer? timer;

    void scheduleNextTick() {
      if (controller.isClosed) return;

      final now = clock.now();
      controller.add(now);

      final msUntilNextMinute = 60000 - (now.millisecondsSinceEpoch % 60000);
      timer = Timer(
        Duration(milliseconds: msUntilNextMinute),
        scheduleNextTick,
      );
    }

    scheduleNextTick();

    ref.onDispose(() {
      timer?.cancel();
      controller.close();
    });

    return controller.stream;
  },
  name: 'minuteTickerProvider',
  retry: (_, _) => null,
);
