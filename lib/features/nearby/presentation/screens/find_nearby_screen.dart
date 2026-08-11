import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/nearby_provider.dart';
import '../widgets/nearby_search_bar.dart';
import '../widgets/nearby_filter_chips.dart';
import '../widgets/nearby_map.dart';
import '../widgets/facility_bottom_sheet.dart';
import '../widgets/location_permission_view.dart';
import '../widgets/nearby_empty_state.dart';

class FindNearbyScreen extends ConsumerStatefulWidget {
  final String initialCategory;
  
  const FindNearbyScreen({super.key, this.initialCategory = 'All'});

  @override
  ConsumerState<FindNearbyScreen> createState() => _FindNearbyScreenState();
}

class _FindNearbyScreenState extends ConsumerState<FindNearbyScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = [
    'All', 'Hospitals', 'Health Centers', 'Clinics', 'Midwives', 'Pharmacies', 'Emergency'
  ];
  late String _currentUiCategory;

  @override
  void initState() {
    super.initState();
    _currentUiCategory = widget.initialCategory;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialFacilities();
    });
  }
  
  void _fetchInitialFacilities() {
    String? apiType;
    if (_currentUiCategory != 'All') {
      if (_currentUiCategory == 'Hospitals') apiType = 'Hospital';
      else if (_currentUiCategory == 'Health Centers') apiType = 'Health Center';
      else if (_currentUiCategory == 'Clinics') apiType = 'Clinic';
      else if (_currentUiCategory == 'Midwives') apiType = 'Midwife';
      else if (_currentUiCategory == 'Pharmacies') apiType = 'Pharmacy';
      else if (_currentUiCategory == 'Emergency') apiType = 'Emergency';
    }
    ref.read(nearbyStateProvider.notifier).fetchNearbyFacilities(type: apiType ?? 'All');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // In a real app, this would debounce and filter the results by name/service
  }

  void _onCategorySelected(String category) {
    setState(() {
      _currentUiCategory = category;
    });
    String? apiType;
    if (category != 'All') {
      if (category == 'Hospitals') apiType = 'Hospital';
      else if (category == 'Health Centers') apiType = 'Health Center';
      else if (category == 'Clinics') apiType = 'Clinic';
      else if (category == 'Midwives') apiType = 'Midwife';
      else if (category == 'Pharmacies') apiType = 'Pharmacy';
      else if (category == 'Emergency') apiType = 'Emergency';
    }
    ref.read(nearbyStateProvider.notifier).updateFilters(type: apiType ?? 'All');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        title: const Text('Find Nearby', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(nearbyStateProvider.notifier).fetchNearbyFacilities(forceRefreshLocation: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            color: const Color(0xFF1B5E20),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: NearbySearchBar(
              controller: _searchController,
              onClear: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              onChanged: _onSearchChanged,
            ),
          ),
          
          // State Rendering
          Expanded(
            child: _buildBody(state),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(NearbyState state) {
    if (state is NearbyInitial || state is NearbyLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
      );
    }
    
    if (state is NearbyLocationDisabled) {
      return LocationPermissionView(
        isDisabled: true,
        onRetry: () => ref.read(nearbyStateProvider.notifier).fetchNearbyFacilities(),
      );
    }

    if (state is NearbyLocationPermissionDenied) {
      return LocationPermissionView(
        isPermanentlyDenied: state.isPermanent,
        onRetry: () => ref.read(nearbyStateProvider.notifier).fetchNearbyFacilities(),
      );
    }

    if (state is NearbyError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(nearbyStateProvider.notifier).fetchNearbyFacilities(),
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    // Success states (Empty or Loaded)
    final bool isEmpty = state is NearbyEmpty;
    final position = isEmpty ? (state).userLocation : (state as NearbyLoaded).userLocation;
    final type = isEmpty ? (state).selectedType : (state as NearbyLoaded).selectedType;
    final radius = isEmpty ? (state).radius : (state as NearbyLoaded).radius;
    final facilities = isEmpty ? [] : (state as NearbyLoaded).facilities;

    // Map Category UI name back from API type
    String uiCategory = 'All';
    if (type == 'Hospital') uiCategory = 'Hospitals';
    else if (type == 'Health Center') uiCategory = 'Health Centers';
    else if (type == 'Clinic') uiCategory = 'Clinics';
    else if (type == 'Midwife') uiCategory = 'Midwives';
    else if (type == 'Pharmacy') uiCategory = 'Pharmacies';
    else if (type == 'Emergency') uiCategory = 'Emergency';

    return Stack(
      children: [
        Column(
          children: [
            NearbyFilterChips(
              categories: _categories,
              selectedCategory: uiCategory,
              onSelected: _onCategorySelected,
            ),
            Expanded(
              child: Stack(
                children: [
                  NearbyMap(
                    userLocation: position,
                    facilities: facilities.cast(),
                    onFacilitySelected: (facility) {
                      // Handled by marker tap
                    },
                    onMyLocationTapped: () {
                      ref.read(nearbyStateProvider.notifier).fetchNearbyFacilities(forceRefreshLocation: true);
                    },
                  ),
                  if (isEmpty)
                    Container(
                      color: Colors.white.withOpacity(0.9),
                      child: NearbyEmptyState(
                        onExpandRadius: () {
                          ref.read(nearbyStateProvider.notifier).updateFilters(radius: radius + 5.0);
                        },
                        onClearFilters: () {
                          ref.read(nearbyStateProvider.notifier).updateFilters(type: 'All', service: 'All');
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (!isEmpty)
          FacilityBottomSheet(
            facilities: facilities.cast(),
            radius: radius,
          ),
      ],
    );
  }
}
