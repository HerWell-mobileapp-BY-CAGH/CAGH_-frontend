/// App-wide constant values that are not environment-specific.
///
/// Centralizes external service URLs and placeholder assets so they are not
/// hardcoded across multiple UI/network files.
class AppConstants {
  // Placeholder avatar image (used when no profile photo is available).
  static const String placeholderAvatarUrl = 'https://i.pravatar.cc/150?img=47';

  // Google Maps search fallback URL builder for a facility's geo-coordinates.
  static String googleMapsSearchUrl(dynamic latitude, dynamic longitude) =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
}
