import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/healthcare_facility.dart';
import '../providers/nearby_provider.dart';
import 'find_nearby_screen.dart';
import '../widgets/facility_card.dart';
import 'package:cagh_frontend/shared/widgets/standard_app_bar.dart';
class NearbyHealthcareScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  const NearbyHealthcareScreen({super.key, this.showBackButton = true});

  @override
  ConsumerState<NearbyHealthcareScreen> createState() => _NearbyHealthcareScreenState();
}

class _NearbyHealthcareScreenState extends ConsumerState<NearbyHealthcareScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Hospital', 'Clinic', 'Pharmacy'
  ];


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nearbyStateProvider.notifier).fetchNearbyFacilities(type: 'All');
    });
  }

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
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF315E26)),
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



  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyStateProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF315E26),
        elevation: 0,
        centerTitle: true,
        leading: widget.showBackButton ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ) : null,
        title: const Text('Healthcare Near You', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () => _navigateToFindNearby(),
              icon: const Icon(Icons.location_on, color: Colors.white, size: 16),
              label: const Text('Find Nearby', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF4C7B41), // slightly lighter green for the button
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find trusted maternal and reproductive healthcare services around you.',
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4EE), // Green like find midwife
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      readOnly: true,
                      onTap: () => _navigateToFindNearby(),
                      decoration: const InputDecoration(
                        hintText: 'Search hospitals, clinics, midwives...',
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF315E26)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

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


            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
