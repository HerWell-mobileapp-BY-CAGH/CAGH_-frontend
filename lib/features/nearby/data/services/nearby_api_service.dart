import 'dart:math';

/// A mock API service to simulate fetching healthcare facilities from the backend.
class NearbyApiService {
  Future<List<Map<String, dynamic>>> fetchNearbyFacilities({
    required double latitude,
    required double longitude,
    required double radius,
    String? type,
    String? service,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Generate mock data centered around the provided location
    final random = Random();
    
    List<Map<String, dynamic>> mockData = [
      {
        'id': '1',
        'name': 'Bole Health Center',
        'type': 'Health Center',
        'latitude': latitude + (random.nextDouble() - 0.5) * 0.02,
        'longitude': longitude + (random.nextDouble() - 0.5) * 0.02,
        'distance': 1.8,
        'address': 'Bole, Addis Ababa',
        'phone': '+251 911 123 456',
        'is_open': true,
        'emergency_available': true,
        'verified': true,
        'services': ['ANC', 'Maternal', 'Family Planning'],
        'opening_hours': ['Mon-Fri: 24 Hours', 'Weekend: 8 AM - 6 PM'],
        'rating': 4.5,
      },
      {
        'id': '2',
        'name': 'Zewditu Memorial Hospital',
        'type': 'Hospital',
        'latitude': latitude + (random.nextDouble() - 0.5) * 0.04,
        'longitude': longitude + (random.nextDouble() - 0.5) * 0.04,
        'distance': 3.5,
        'address': 'Kirkos, Addis Ababa',
        'phone': '+251 115 51 51 00',
        'is_open': true,
        'emergency_available': true,
        'verified': true,
        'services': ['Surgery', 'Maternal', 'Emergency', 'ANC', 'Mental Health'],
        'opening_hours': ['24/7'],
        'rating': 4.8,
      },
      {
        'id': '3',
        'name': 'St. Mary Clinic',
        'type': 'Clinic',
        'latitude': latitude + (random.nextDouble() - 0.5) * 0.015,
        'longitude': longitude + (random.nextDouble() - 0.5) * 0.015,
        'distance': 0.8,
        'address': 'Kality, Addis Ababa',
        'phone': null,
        'is_open': false,
        'emergency_available': false,
        'verified': false,
        'services': ['General Checkup', 'Family Planning', 'Nutrition'],
        'opening_hours': ['Mon-Sat: 8 AM - 5 PM'],
        'rating': 3.9,
      },
      {
        'id': '4',
        'name': 'Sister Hannah M.',
        'type': 'Midwife',
        'latitude': latitude + (random.nextDouble() - 0.5) * 0.01,
        'longitude': longitude + (random.nextDouble() - 0.5) * 0.01,
        'distance': 0.4,
        'address': 'Mobile Service',
        'phone': '+251 922 45 67 89',
        'is_open': true,
        'emergency_available': false,
        'verified': true,
        'services': ['Pregnancy Care', 'ANC', 'Home Delivery'],
        'opening_hours': ['Mon-Sun: 7 AM - 7 PM'],
        'rating': 5.0,
      },
      {
        'id': '5',
        'name': 'Kenema Pharmacy',
        'type': 'Pharmacy',
        'latitude': latitude + (random.nextDouble() - 0.5) * 0.03,
        'longitude': longitude + (random.nextDouble() - 0.5) * 0.03,
        'distance': 2.1,
        'address': 'Piassa, Addis Ababa',
        'phone': '+251 111 22 33 44',
        'is_open': true,
        'emergency_available': false,
        'verified': true,
        'services': ['Contraceptives', 'Menstrual Health', 'First Aid'],
        'opening_hours': ['Mon-Sun: 8 AM - 10 PM'],
        'rating': 4.2,
      },
    ];

    // Filter by type if provided
    if (type != null && type != 'All') {
      mockData = mockData.where((facility) {
        if (type == 'Emergency') {
          return facility['emergency_available'] == true;
        }
        return facility['type'] == type;
      }).toList();
    }

    // Filter by service if provided
    if (service != null && service != 'All') {
      mockData = mockData.where((facility) {
        final List<String> services = List<String>.from(facility['services']);
        return services.contains(service);
      }).toList();
    }

    return mockData;
  }
}
