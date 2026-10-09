import 'dart:developer' as developer;

/// Lightweight diagnostic logger for GramTransit.
///
/// Uses [dart:developer] — no external logging dependency.
///
/// Privacy rules — never log:
/// - user-entered text, search queries, or location coordinates
/// - tokens, credentials, or any secret
/// - preference values or personal data
/// - full provider state or [AsyncValue] contents
///
/// Safe to log: event names, logging keys, failure types, and
/// sanitised exception type/message diagnostics.
final class AppLogger {
  const AppLogger();

  static const String _name = 'GramTransit';

  // dart:developer level constants (mirrors java.util.logging):
  // FINE=500, INFO=800, WARNING=900, SEVERE=1000

  /// Logs a debug-level message.
  ///
  /// Suppressed in release builds — use for verbose diagnostic output only.
  void debug(String message) {
    assert(() {
      developer.log(message, name: _name, level: 500);
      return true;
    }());
  }

  /// Logs an info-level message (e.g. lifecycle events, safe startup facts).
  ///
  /// Suppressed in release builds.
  void info(String message) {
    assert(() {
      developer.log(message, name: _name, level: 800);
      return true;
    }());
  }

  /// Logs a warning-level message.
  ///
  /// Suppressed in release builds. Use for recoverable unexpected conditions.
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    assert(() {
      developer.log(
        message,
        name: _name,
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
      return true;
    }());
  }

  /// Logs an error-level message.
  ///
  /// Visible in ALL build modes including release.
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
