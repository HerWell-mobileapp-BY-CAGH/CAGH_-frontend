import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/nearby_provider.dart';
import 'find_nearby_screen.dart';
import 'facility_details_screen.dart';
import 'midwife_detail_screen.dart';
import '../../domain/entities/healthcare_facility.dart';
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
  String _searchQuery = '';
  String _selectedCategory = 'All';

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

  void _openFacilityDetails(HealthcareFacility facility) {
    if (facility.type == 'Midwife') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MidwifeDetailScreen(facility: facility),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FacilityDetailsScreen(facility: facility),
        ),
      );
    }
  }

  Widget _buildCategoryChip(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedCategory.toLowerCase() == title.toLowerCase();

    String displayTitle = title;
    if (title == 'Hospital') displayTitle = AppLocalizations.of(context)!.hospital.toUpperCase();
    if (title == 'Clinic') displayTitle = AppLocalizations.of(context)!.clinic;
    if (title == 'Pharmacy') displayTitle = AppLocalizations.of(context)!.pharmacy;

    final chipBg = isSelected
        ? AppColors.primaryGreen
        : (isDark ? AppColors.darkSurfaceVariant : Colors.white);
    final chipBorder = isSelected
        ? AppColors.primaryGreen
        : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0));
    final chipColor = isSelected
        ? Colors.white
        : (isDark ? AppColors.darkPrimary : AppColors.primaryGreen);
    final textColor = isSelected
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF1E293B));

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedCategory.toLowerCase() == title.toLowerCase()) {
            _selectedCategory = 'All';
          } else {
            _selectedCategory = title;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: chipBorder, width: 1.2),
          boxShadow: [
            if (!isDark && !isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: chipColor, size: 18),
            const SizedBox(width: 8),
            Text(
              displayTitle,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Hospital':
        return Icons.add_box_rounded;
      case 'Clinic':
        return Icons.medical_services_rounded;
      case 'Pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'Health Center':
        return Icons.business_rounded;
      case 'Midwife':
        return Icons.pregnant_woman_rounded;
      default:
        return Icons.local_hospital_rounded;
    }
  }

  Widget _buildMiniMapThumbnail() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECE4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD2DCD0), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(64, 64),
              painter: _MiniMapPainter(),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: const Color(0xFFD32F2F),
                  size: 24,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                Container(
                  width: 6,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityGridCard(HealthcareFacility facility, bool isDark) {
    final ratingVal = facility.rating ?? 4.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openFacilityDetails(facility),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      facility.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(${facility.distance.toStringAsFixed(1)}km)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (starIdx) {
                        final filled = starIdx < ratingVal.round();
                        return Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: filled
                              ? const Color(0xFFF5A623)
                              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildMiniMapThumbnail(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreNearbyRow(HealthcareFacility facility, bool isDark) {
    final ratingVal = facility.rating ?? 4.0;
    IconData iconData;
    switch (facility.type) {
      case 'Hospital':
        iconData = Icons.add_box_rounded;
        break;
      case 'Pharmacy':
        iconData = Icons.local_pharmacy_rounded;
        break;
      case 'Clinic':
        iconData = Icons.medical_services_rounded;
        break;
      case 'Midwife':
        iconData = Icons.pregnant_woman_rounded;
        break;
      default:
        iconData = Icons.local_hospital_rounded;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openFacilityDetails(facility),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(
                iconData,
                color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${facility.name} (${facility.distance.toStringAsFixed(1)}km)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (starIdx) {
                  final filled = starIdx < ratingVal.round();
                  return Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: filled
                        ? const Color(0xFFF5A623)
                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nearbyState = ref.watch(nearbyStateProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.showBackButton
          ? AppBar(
              backgroundColor: AppColors.primaryGreen,
              elevation: 0,
              centerTitle: false,
              titleSpacing: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                AppLocalizations.of(context)!.healthcareNearYou,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton.icon(
                    onPressed: () => _navigateToFindNearby(),
                    icon: const Icon(Icons.location_on, color: Colors.white, size: 16),
                    label: Text(
                      AppLocalizations.of(context)!.findNearby,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.buttonGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                  ),
                ),
              ],
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: NearbySearchBar(
              controller: _searchController,
              onClear: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              onFilterTapped: () {
                cagh_frontend_filter.SearchFilterBottomSheet.show(
                  context,
                  isForMidwife: false,
                  onApply: (distanceStr, rating, availability) {
                    _navigateToFindNearby();
                  },
                );
              },
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upper Find Nearby Button (matching design reference)
                  if (!widget.showBackButton)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _navigateToFindNearby(),
                          icon: Icon(
                            Icons.location_on,
                            color: isDark ? AppColors.darkPrimary : AppColors.primaryGreen,
                            size: 16,
                          ),
                          label: Text(
                            AppLocalizations.of(context)!.findNearby,
                            style: TextStyle(
                              color: isDark ? AppColors.darkPrimary : AppColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.darkPrimary.withValues(alpha: 0.15)
                                : AppColors.primaryGreen.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Header: "Find Care By Type"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      AppLocalizations.of(context)!.findCareByType,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Category Chips
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryChip(
                          _categories[index],
                          _getIconForCategory(_categories[index]),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Real Facilities Section
                  _buildRealFacilitiesSection(nearbyState, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealFacilitiesSection(NearbyState state, bool isDark) {
    if (state is NearbyLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    if (state is NearbyError) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.message,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.red.shade900,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: () => ref
                  .read(nearbyStateProvider.notifier)
                  .fetchNearbyFacilities(forceRefreshLocation: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    List<HealthcareFacility> facilities = [];
    if (state is NearbyLoaded) {
      facilities = state.facilities;
    } else if (state is NearbyEmpty) {
      facilities = [];
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      facilities = facilities.where((f) {
        return f.name.toLowerCase().contains(_searchQuery) ||
            f.address.toLowerCase().contains(_searchQuery) ||
            f.type.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      facilities = facilities.where((f) {
        return f.type.toLowerCase() == _selectedCategory.toLowerCase();
      }).toList();
    }

    if (facilities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.location_off_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No facilities found',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Try adjusting your search or category filter',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedCategory = 'All';
                  });
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ),
        ),
      );
    }

    // Split into Cards (top up to 6) and More Results
    final cardFacilities = facilities.take(6).toList();
    final listFacilities = facilities.length > 6
        ? facilities.skip(6).toList()
        : (facilities.length > 3 ? facilities.sublist(2) : facilities);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Responsive Cards Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 768;
              final isTablet = constraints.maxWidth >= 520 && constraints.maxWidth < 768;
              final columns = isDesktop ? 3 : (isTablet ? 2 : 1);
              final cardWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cardFacilities.map((facility) {
                  return SizedBox(
                    width: cardWidth,
                    child: _buildFacilityGridCard(facility, isDark),
                  );
                }).toList(),
              );
            },
          ),
        ),

        const SizedBox(height: 28),

        // "More Nearby Results" Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'More Nearby Results',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: listFacilities.map((facility) {
              return _buildMoreNearbyRow(facility, isDark);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFE8ECE4);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Park green zone
    final parkPaint = Paint()..color = const Color(0xFFD6E8D0);
    final parkPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.45, 0)
      ..lineTo(size.width * 0.25, size.height * 0.5)
      ..lineTo(0, size.height * 0.35)
      ..close();
    canvas.drawPath(parkPath, parkPaint);

    // Water blue curve
    final waterPaint = Paint()..color = const Color(0xFFD0E2EC);
    final waterPath = Path()
      ..moveTo(size.width * 0.7, 0)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.3, size.width, size.height * 0.4)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(waterPath, waterPaint);

    // Roads (white paths with subtle grey border)
    final roadBorderPaint = Paint()
      ..color = const Color(0xFFD5DDD0)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke;

    // Road 1: diagonal
    final road1 = Path()
      ..moveTo(0, size.height * 0.75)
      ..lineTo(size.width, size.height * 0.25);
    canvas.drawPath(road1, roadBorderPaint);
    canvas.drawPath(road1, roadPaint);

    // Road 2: cross street
    final road2 = Path()
      ..moveTo(size.width * 0.25, 0)
      ..lineTo(size.width * 0.75, size.height);
    canvas.drawPath(road2, roadBorderPaint);
    canvas.drawPath(road2, roadPaint);

    // Road 3: side road
    final road3 = Path()
      ..moveTo(size.width * 0.5, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.75);
    canvas.drawPath(road3, roadBorderPaint);
    canvas.drawPath(road3, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
