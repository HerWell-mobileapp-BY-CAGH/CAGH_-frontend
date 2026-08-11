import '../../domain/entities/healthcare_facility.dart';
import '../../domain/repositories/nearby_repository.dart';
import '../services/nearby_api_service.dart';

class NearbyRepositoryImpl implements NearbyRepository {
  final NearbyApiService _apiService;

  NearbyRepositoryImpl({NearbyApiService? apiService})
      : _apiService = apiService ?? NearbyApiService();

  @override
  Future<List<HealthcareFacility>> getNearbyFacilities({
    required double latitude,
    required double longitude,
    required double radius,
    String? type,
    String? service,
  }) async {
    final List<Map<String, dynamic>> data = await _apiService.fetchNearbyFacilities(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      type: type,
      service: service,
    );

    return data.map((json) => HealthcareFacility(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      distance: json['distance'],
      address: json['address'],
      phone: json['phone'],
      isOpen: json['is_open'],
      emergencyAvailable: json['emergency_available'],
      verified: json['verified'],
      services: List<String>.from(json['services']),
      openingHours: List<String>.from(json['opening_hours']),
      rating: json['rating']?.toDouble(),
    )).toList();
  }
}
