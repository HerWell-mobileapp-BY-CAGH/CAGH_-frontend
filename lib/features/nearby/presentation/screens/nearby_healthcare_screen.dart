import 'package:flutter/material.dart';
import '../../domain/entities/healthcare_facility.dart';
import 'find_nearby_screen.dart';
import '../widgets/facility_card.dart';

class NearbyHealthcareScreen extends StatefulWidget {
  const NearbyHealthcareScreen({super.key});

  @override
  State<NearbyHealthcareScreen> createState() => _NearbyHealthcareScreenState();
}

class _NearbyHealthcareScreenState extends State<NearbyHealthcareScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Hospital', 'Health Center', 'Clinic', 'Midwife', 'Pharmacy', 'Emergency'
  ];

  final List<String> _services = [
    'ANC', 'Pregnancy Care', 'Family Planning', 'Maternal Health',
    'Menstrual Health', 'STI Services', 'Mental Health', 'Nutrition'
  ];

  final List<HealthcareFacility> _mockFacilities = [
    const HealthcareFacility(
      id: '1',
      name: 'St. Paul Hospital Millennium Medical College',
      type: 'Hospital',
      latitude: 9.0560,
      longitude: 38.7360,
      distance: 1.2,
      address: 'Gullele, Addis Ababa',
      phone: '+251 11 275 0125',
      isOpen: true,
      emergencyAvailable: true,
      verified: true,
      services: ['ANC', 'Emergency', 'Surgery', 'Pediatrics'],
      openingHours: ['Mon - Sun: 24 Hours'],
      rating: 4.2,
    ),
    const HealthcareFacility(
      id: '2',
      name: 'Gandhi Memorial Women Hospital',
      type: 'Hospital',
      latitude: 9.0145,
      longitude: 38.7511,
      distance: 3.5,
      address: 'Kirkos, Addis Ababa',
      isOpen: true,
      emergencyAvailable: true,
      verified: true,
      services: ['Maternity', 'ANC', 'Gynecology'],
      openingHours: ['Mon - Sun: 24 Hours'],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToFindNearby({String category = 'All'}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FindNearbyScreen(initialCategory: category)),
    );
  }

  Widget _buildCategoryChip(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        // Map UI category string to API category string if necessary
        String apiCategory = title;
        if (title == 'Hospital') apiCategory = 'Hospitals';
        if (title == 'Health Center') apiCategory = 'Health Centers';
        if (title == 'Clinic') apiCategory = 'Clinics';
        if (title == 'Midwife') apiCategory = 'Midwives';
        if (title == 'Pharmacy') apiCategory = 'Pharmacies';
        
        _navigateToFindNearby(category: apiCategory);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF315E26), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Hospital': return Icons.local_hospital;
      case 'Health Center': return Icons.business;
      case 'Clinic': return Icons.medical_services;
      case 'Midwife': return Icons.pregnant_woman;
      case 'Pharmacy': return Icons.local_pharmacy;
      case 'Emergency': return Icons.emergency;
      default: return Icons.local_hospital;
    }
  }

  Widget _buildServiceChip(String service) {
    return GestureDetector(
      onTap: () {
        _navigateToFindNearby(); // Could pass service filter here later
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFA5D6A7)),
        ),
        child: Text(
          service,
          style: const TextStyle(
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        title: const Text('Healthcare Near You', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () => _navigateToFindNearby(),
              icon: const Icon(Icons.location_on, color: Colors.white, size: 18),
              label: const Text('Find Nearby', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section
            Container(
              width: double.infinity,
              color: const Color(0xFF1B5E20),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find trusted maternal and reproductive healthcare services around you.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      readOnly: true,
                      onTap: () => _navigateToFindNearby(),
                      decoration: const InputDecoration(
                        hintText: 'Search hospitals, clinics, midwives...',
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF1B5E20)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Categories Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Find Care By Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryChip(_categories[index], _getIconForCategory(_categories[index]));
                },
              ),
            ),

            const SizedBox(height: 28),

            // Services Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Find a Service',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                children: _services.map((service) => _buildServiceChip(service)).toList(),
              ),
            ),

            const SizedBox(height: 32),

            // Facilities Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Healthcare Facilities',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
            ),
            const SizedBox(height: 12),
            ..._mockFacilities.map((facility) => FacilityCard(facility: facility)),

            const SizedBox(height: 24),

            // Emergency Banner
            GestureDetector(
              onTap: () => _navigateToFindNearby(category: 'Emergency'),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD32F2F).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emergency, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need Emergency Care?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Find emergency facilities',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Find Now',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
