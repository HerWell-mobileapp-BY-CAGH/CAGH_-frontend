import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/nearby_provider.dart';
import 'find_nearby_screen.dart';
import '../widgets/nearby_map.dart';
import '../widgets/facility_bottom_sheet.dart';
import '../widgets/nearby_search_bar.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/widgets/search_filter_bottom_sheet.dart' as cagh_frontend_filter;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String displayTitle = title;
    if (title == 'Hospital') displayTitle = AppLocalizations.of(context)!.hospital;
    if (title == 'Clinic') displayTitle = AppLocalizations.of(context)!.clinic;
    if (title == 'Pharmacy') displayTitle = AppLocalizations.of(context)!.pharmacy;

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
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              displayTitle,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.showBackButton ? AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.healthcareNearYou, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () => _navigateToFindNearby(),
              icon: Icon(Icons.location_on, color: Colors.white, size: 16),
              label: Text(AppLocalizations.of(context)!.findNearby, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.buttonGreen, // slightly lighter green for the button
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
            ),
          )
        ],
      ) : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: NearbySearchBar(
              controller: _searchController,
              onClear: () {
                _searchController.clear();
              },
              onChanged: (val) {},
              onFilterTapped: () {
                cagh_frontend_filter.SearchFilterBottomSheet.show(
                  context,
                  isForMidwife: false,
                  onApply: (distanceStr, rating, availability) {
                    // Passed to FindNearbyScreen in real app, ignore for now
                  },
                );
              },
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.showBackButton)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _navigateToFindNearby(),
                          icon: Icon(Icons.location_on, color: AppColors.primaryGreen, size: 16),
                          label: Text(AppLocalizations.of(context)!.findNearby, style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                        ),
                      ),
                    ),
                  
                  // Top Section
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Text(
                      AppLocalizations.of(context)!.findTrustedMaternal,
                      style: TextStyle(
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade800, 
                          fontSize: 14, 
                          height: 1.4),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Categories Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      AppLocalizations.of(context)!.findCareByType,
                      style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: isDark ? Colors.white : AppColors.textDark),
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

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
