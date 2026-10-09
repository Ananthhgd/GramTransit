import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/time/clock.dart';
import 'package:gramtransit_passenger/core/time/time_providers.dart';

final class _FakeClock implements Clock {
  final DateTime _now = DateTime(2026, 1, 1, 12, 0, 0);

  @override
  DateTime now() => _now;
}

void main() {
  group('Time Providers', () {
    test('clockProvider defaults to SystemClock', () {
      final container = ProviderContainer(retry: (_, _) => null);
      addTearDown(container.dispose);

      final clock = container.read(clockProvider);
      expect(clock, isA<SystemClock>());
    });

    test('minuteTickerProvider emits initial time immediately', () async {
      final fakeClock = _FakeClock();
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(fakeClock)],
        retry: (_, _) => null,
      );
      addTearDown(container.dispose);

      // Start the stream provider by listening to it.
      final subscription = container.listen(minuteTickerProvider, (_, _) {});

      // Wait for the first event. This will not trigger real-time waiting
      // because the first event is emitted synchronously upon startup.
      final initialTime = await container.read(minuteTickerProvider.future);
      expect(initialTime, fakeClock.now());

      subscription.close();
    });

    test('minuteTickerProvider auto-disposes and cancels timers when listeners are removed', () async {
      final fakeClock = _FakeClock();
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(fakeClock)],
        retry: (_, _) => null,
      );
      addTearDown(container.dispose);

      var subscription = container.listen(minuteTickerProvider, (_, _) {});

      // Wait for the synchronous initial tick to ensure the provider is fully mounted and active.
      await container.read(minuteTickerProvider.future);
      expect(container.exists(minuteTickerProvider), isTrue);

      // Close the only listener. This triggers autoDispose.
      subscription.close();

      // Allow the microtask queue and event loop to process the Riverpod disposal.
      await Future<void>.delayed(Duration.zero);

      // Ensure the provider no longer exists in the container.
      // Its onDispose callback will have executed, closing the controller
      // and canceling any pending Timer.
      expect(container.exists(minuteTickerProvider), isFalse);
    });
  });
}
