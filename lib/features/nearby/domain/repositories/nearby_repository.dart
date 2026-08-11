import '../entities/healthcare_facility.dart';

abstract class NearbyRepository {
  Future<List<HealthcareFacility>> getNearbyFacilities({
    required double latitude,
    required double longitude,
    required double radius,
    String? type,
    String? service,
  });
}
