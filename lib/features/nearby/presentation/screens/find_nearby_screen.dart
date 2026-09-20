import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/nearby_provider.dart';
import '../widgets/nearby_search_bar.dart';
import '../widgets/nearby_filter_chips.dart';
import '../widgets/facility_card.dart';
import '../widgets/location_permission_view.dart';
import '../widgets/nearby_empty_state.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/widgets/inner_page_app_bar.dart';
import 'package:cagh_frontend/shared/widgets/search_filter_bottom_sheet.dart' as cagh_frontend_filter;

class FindNearbyScreen extends ConsumerStatefulWidget {
  final String initialCategory;
  
  const FindNearbyScreen({super.key, this.initialCategory = 'All'});

  @override
  ConsumerState<FindNearbyScreen> createState() => _FindNearbyScreenState();
}

class _FindNearbyScreenState extends ConsumerState<FindNearbyScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = [
    'All', 'Hospitals', 'Clinics', 'Pharmacies'
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
      if (_currentUiCategory == 'Hospitals') {
        apiType = 'Hospital';
      } else if (_currentUiCategory == 'Health Centers') {
        apiType = 'Health Center';
      } else if (_currentUiCategory == 'Clinics') {
        apiType = 'Clinic';
      } else if (_currentUiCategory == 'Midwives') {
        apiType = 'Midwife';
      } else if (_currentUiCategory == 'Pharmacies') {
        apiType = 'Pharmacy';
      } else if (_currentUiCategory == AppLocalizations.of(context)!.emergency) {
        apiType = AppLocalizations.of(context)!.emergency;
      }
    }
    ref.read(nearbyStateProvider.notifier).fetchNearbyFacilities(type: apiType ?? 'All');
  }

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_searchQuery != query) {
      setState(() {
        _searchQuery = query.trim().toLowerCase();
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _currentUiCategory = category;
    });
    String? apiType;
    if (category != 'All') {
      if (category == 'Hospitals') {
        apiType = 'Hospital';
      } else if (category == 'Health Centers') {
        apiType = 'Health Center';
      } else if (category == 'Clinics') {
        apiType = 'Clinic';
      } else if (category == 'Midwives') {
        apiType = 'Midwife';
      } else if (category == 'Pharmacies') {
        apiType = 'Pharmacy';
      } else if (category == AppLocalizations.of(context)!.emergency) {
        apiType = AppLocalizations.of(context)!.emergency;
      }
    }
    ref.read(nearbyStateProvider.notifier).updateFilters(type: apiType ?? 'All');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyStateProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildInnerPageAppBar(
        context,
        title: AppLocalizations.of(context)!.findNearby,
        showLanguage: true,
        extraActions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.read(nearbyStateProvider.notifier).fetchNearbyFacilities(forceRefreshLocation: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: NearbySearchBar(
              controller: _searchController,
              onClear: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              onChanged: _onSearchChanged,
              onFilterTapped: () {
                cagh_frontend_filter.SearchFilterBottomSheet.show(
                  context,
                  isForMidwife: false,
                  onApply: (distanceStr, rating, availability) {
                    final distance = double.tryParse(distanceStr) ?? 10.0;
                    ref.read(nearbyStateProvider.notifier).updateFilters(radius: distance);
                  },
                );
              },
            ),
          ),

          // Horizontally scrollable category filter chips (fixed, non-scrollable vertically)
          NearbyFilterChips(
            categories: _categories,
            selectedCategory: _currentUiCategory,
            onSelected: _onCategorySelected,
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

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
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
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
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(nearbyStateProvider.notifier).fetchNearbyFacilities(),
              child: Text(AppLocalizations.of(context)!.retry),
            )
          ],
        ),
      );
    }

    final bool isEmpty = state is NearbyEmpty;
    final radius = isEmpty ? (state).radius : (state as NearbyLoaded).radius;
    final allFacilities = isEmpty ? [] : (state as NearbyLoaded).facilities;

    final facilities = _searchQuery.isEmpty
        ? allFacilities
        : allFacilities.where((f) {
            final q = _searchQuery;
            return f.name.toLowerCase().contains(q) ||
                f.type.toLowerCase().contains(q) ||
                f.address.toLowerCase().contains(q) ||
                f.services.any((s) => s.toLowerCase().contains(q));
          }).toList();

    if (facilities.isEmpty) {
      return NearbyEmptyState(
        onExpandRadius: () {
          ref.read(nearbyStateProvider.notifier).updateFilters(radius: radius + 50.0);
        },
        onClearFilters: () {
          _searchController.clear();
          _onSearchChanged('');
          ref.read(nearbyStateProvider.notifier).updateFilters(type: 'All', service: 'All');
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: facilities.length,
      itemBuilder: (context, index) {
        return FacilityCard(facility: facilities[index]);
      },
    );
  }
}
