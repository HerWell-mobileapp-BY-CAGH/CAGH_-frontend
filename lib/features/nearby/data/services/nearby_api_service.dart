import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../../domain/entities/healthcare_facility.dart';

class NearbyApiService {
  Future<List<HealthcareFacility>> fetchNearbyFacilities({
    required double latitude,
    required double longitude,
    required double radius,
    String? type,
    String? service,
  }) async {
    if (ApiConfig.useMockData) {
      // Mock data logic can remain or be simplified. Returning empty for now.
      return [];
    }

    try {
      print('[DIAGNOSTIC] GPS latitude from device: $latitude');
      print('[DIAGNOSTIC] GPS longitude from device: $longitude');
      print('[DIAGNOSTIC] Search radius (km): $radius');

      final queryParams = {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius_km': radius.toString(),
        if (type != null && type != 'All') 'facility_type': type,
        if (service != null && service != 'All') 'q': service, // map service to free text search for now
      };

      print('[DIAGNOSTIC] lat sent to API: ${queryParams['lat']}');
      print('[DIAGNOSTIC] lng sent to API: ${queryParams['lng']}');

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.facilities}').replace(queryParameters: queryParams);
      print('[DIAGNOSTIC] API URL/Request parameters: $uri');
      
      final response = await http.get(uri);

      print('[DIAGNOSTIC] HTTP status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('[DIAGNOSTIC] Number of facilities returned: ${data.length}');
        return data.map((json) => HealthcareFacility.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load facilities');
      }
    } catch (e) {
      print('Error fetching facilities: $e');
      throw Exception('Failed to fetch facilities: $e');
    }
  }
}
