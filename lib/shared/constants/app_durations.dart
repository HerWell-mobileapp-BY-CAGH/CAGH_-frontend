/// Named duration constants to replace magic-number timeouts.
class AppDurations {
  /// Standard network request timeout used across API services (accommodates cold starts).
  static const Duration apiRequestTimeout = Duration(seconds: 45);
}
