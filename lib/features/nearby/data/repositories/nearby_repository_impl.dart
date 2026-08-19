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
    return await _apiService.fetchNearbyFacilities(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      type: type,
      service: service,
    );
  }
}
