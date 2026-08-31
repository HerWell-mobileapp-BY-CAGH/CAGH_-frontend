import 'package:cagh_frontend/l10n/app_localizations.dart';
class HealthcareFacility {
  final String id;
  final String name;
  final String type; // e.g., 'Hospital', 'Clinic', 'Pharmacy'
  final double latitude;
  final double longitude;
  final double distance; // in km
  final String address;
  final String? phone;
  final bool isOpen;
  final bool emergencyAvailable;
  final bool verified;
  final List<String> services;
  final String? operatingHours;
  final double? rating;
  final String? image;
  final String? callUrl;
  final Map<String, dynamic>? navigationUrls;

  const HealthcareFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.address,
    this.phone,
    required this.isOpen,
    required this.emergencyAvailable,
    required this.verified,
    required this.services,
    this.operatingHours,
    this.rating,
    this.image,
    this.callUrl,
    this.navigationUrls,
  });

  factory HealthcareFacility.fromJson(Map<String, dynamic> json) {
    return HealthcareFacility(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['facility_type'] ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) ?? 0.0 : 0.0,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) ?? 0.0 : 0.0,
      distance: json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) ?? 0.0 : 0.0,
      address: json['address'] ?? '',
      phone: json['phone_number'],
      isOpen: json['is_active'] ?? true, // use is_active for open status for now
      emergencyAvailable: (json['available_services'] as List<dynamic>?)?.contains('Emergency') ?? false,
      verified: true, // Assuming true for now
      services: (json['available_services'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      operatingHours: json['operating_hours'],
      rating: json['rating_average'] != null ? double.tryParse(json['rating_average'].toString()) : null,
      image: json['image'],
      callUrl: json['call_url'],
      navigationUrls: json['navigation_urls'] as Map<String, dynamic>?,
    );
  }
}
