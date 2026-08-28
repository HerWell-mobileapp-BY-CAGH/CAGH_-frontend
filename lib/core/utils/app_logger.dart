import 'package:flutter/foundation.dart';

/// Centralized, debug-gated logging.
///
/// Replaces ad-hoc [debugPrint] calls so logging is routed through a single
/// point and is suppressed in release builds (addressing the "debug printing
/// in production code" concern). Swap the body of these methods to route to a
/// remote logger (e.g. Sentry, Crashlytics) without touching call sites.
class AppLogger {
  static const bool _enabled = kDebugMode;

  /// Debug/informational log.
  static void d(String message) {
    if (_enabled) debugPrint(message);
  }

  /// Error log with an optional stack trace.
  static void e(String context, Object error, [StackTrace? stackTrace]) {
    if (_enabled) {
      debugPrint('[$context] ERROR: $error'
          '${stackTrace != null ? '\n$stackTrace' : ''}');
    }
  }
}
