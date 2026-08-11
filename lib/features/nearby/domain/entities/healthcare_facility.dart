class HealthcareFacility {
  final String id;
  final String name;
  final String type; // e.g., 'Hospital', 'Clinic', 'Midwife'
  final double latitude;
  final double longitude;
  final double distance; // in km
  final String address;
  final String? phone;
  final bool isOpen;
  final bool emergencyAvailable;
  final bool verified;
  final List<String> services;
  final List<String> openingHours;
  final double? rating;

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
    required this.openingHours,
    this.rating,
  });
}
