import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cagh_frontend/features/consultations/presentation/user/midwife_profile_detail_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/chat_screen.dart';
import 'package:cagh_frontend/shared/widgets/inner_page_app_bar.dart';
import 'package:cagh_frontend/shared/widgets/search_filter_bottom_sheet.dart' as cagh_frontend_filter;
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class FindMidwifeScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const FindMidwifeScreen({super.key, this.onBack});

  @override
  State<FindMidwifeScreen> createState() => _FindMidwifeScreenState();
}

class _FindMidwifeScreenState extends State<FindMidwifeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  bool _isLoading = true;
  String? _errorMessage;
  final _repository = MidwifeRepositoryImpl(MidwifeApiService());
  List<MidwifeProfile> _midwives = [];
  List<MidwifeProfile> _filteredMidwives = [];

  // Active filters
  String _filterSpecialization = 'Any';
  String _filterRating = 'Any';
  String _filterConsultationType = 'Any';

  @override
  void initState() {
    super.initState();
    _fetchMidwives();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMidwives() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _repository.getMidwives(search: _searchQuery);
      if (mounted) {
        setState(() {
          final verified = data.where((m) =>
            m.verificationStatus.toUpperCase() == 'APPROVED' ||
            m.verificationStatus.toUpperCase() == 'VERIFIED'
          ).toList();
          _midwives = verified.isNotEmpty ? verified : data;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.e('FindMidwifeScreen', e, stack);
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)?.failedToLoadMidwives ?? 'Failed to load midwives. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    _filteredMidwives = _midwives.where((m) {
      // Specialization filter
      if (_filterSpecialization != 'Any') {
        final spec = m.specialty.toLowerCase();
        if (!spec.contains(_filterSpecialization.toLowerCase())) return false;
      }
      // Rating filter
      if (_filterRating != 'Any') {
        final minRating = double.tryParse(_filterRating.split(' ').first) ?? 0.0;
        if (m.ratingAverage < minRating) return false;
      }
      // Consultation type filter
      if (_filterConsultationType == 'In-Person' && !m.supportsInPerson) return false;
      if (_filterConsultationType == 'Voice Call' && !m.supportsVoiceCall) return false;
      return true;
    }).toList();
  }

  String _getLocalizedSpecialty(BuildContext context, String specialty) {
    final lower = specialty.toLowerCase();
    final l10n = AppLocalizations.of(context)!;
    if (lower.contains('maternal') || lower.isEmpty) {
      return l10n.maternalHealthSpecialist;
    } else if (lower.contains('prenatal')) {
      return l10n.prenatalCare;
    } else if (lower.contains('postnatal')) {
      return l10n.postnatalCare;
    } else if (lower.contains('labor') || lower.contains('delivery')) {
      return l10n.laborAndDelivery;
    } else if (lower.contains('family planning')) {
      return l10n.familyPlanning;
    }
    return specialty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildInnerPageAppBar(
        context,
        title: AppLocalizations.of(context)!.findAMidwife,
        onBack: widget.onBack,
        showLanguage: true,
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed Search Input Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100, // Gray background
                          borderRadius: BorderRadius.circular(14), // Rounded rectangle
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                            if (_debounce?.isActive ?? false) _debounce!.cancel();
                            _debounce = Timer(const Duration(milliseconds: 500), () {
                              _fetchMidwives();
                            });
                          },
                          decoration: InputDecoration(
                            icon: Icon(Icons.search, color: Colors.grey.shade600, size: 22),
                            hintText: AppLocalizations.of(context)!.searchByNameOrSpecialty,
                            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryGreen, width: 1.5),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.filter_alt_outlined, color: AppColors.primaryGreen),
                        onPressed: () {
                          cagh_frontend_filter.SearchFilterBottomSheet.show(
                            context,
                            isForMidwife: true,
                            onApply: (specialization, rating, consultationType) {
                              setState(() {
                                _filterSpecialization = specialization;
                                _filterRating = rating;
                                _filterConsultationType = consultationType;
                                _applyFilters();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40.0),
                            child: CircularProgressIndicator(color: AppColors.primaryGreen),
                          ),
                        )
                else if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Column(
                        children: [
                          Text(AppLocalizations.of(context)!.failedToLoadMidwives, style: TextStyle(color: Colors.red.shade700)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _fetchMidwives,
                            child: Text(AppLocalizations.of(context)!.retry),
                          )
                        ],
                      ),
                    ),
                  )
                else if (_filteredMidwives.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Text(
                        _midwives.isEmpty
                            ? AppLocalizations.of(context)!.noMidwivesAvailable
                            : AppLocalizations.of(context)!.noMidwivesMatchFilters,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  // Midwife Cards List
                  ..._filteredMidwives.map((mw) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.lightGreen,
                              backgroundImage: mw.avatarUrl != null ? NetworkImage(mw.avatarUrl!) : null,
                              child: mw.avatarUrl == null 
                                ? Icon(Icons.person, color: Colors.green.shade800, size: 30) 
                                : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            mw.fullName,
                                            style: TextStyle(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).textTheme.bodyLarge?.color,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.cream,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.star, color: AppColors.accentYellow, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              mw.ratingAverage.toStringAsFixed(1),
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getLocalizedSpecialty(context, mw.specialty),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEBF3EA), // Light green
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.home_outlined, size: 14, color: Color(0xFF385A2E)),
                                            const SizedBox(width: 4),
                                            Text(AppLocalizations.of(context)!.inPerson, style: const TextStyle(fontSize: 12, color: Color(0xFF385A2E), fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEBF3EA), // Light green
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.videocam_outlined, size: 14, color: Color(0xFF385A2E)),
                                            const SizedBox(width: 4),
                                            Text(AppLocalizations.of(context)!.voiceCall, style: const TextStyle(fontSize: 12, color: Color(0xFF385A2E), fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Action Buttons Row (Message & View Profile)
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(midwife: mw),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                  label: Text(
                                    AppLocalizations.of(context)!.requestChat,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryGreen,
                                    side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MidwifeProfileDetailScreen(
                                          midwife: mw,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.viewProfile,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),

        ],
      ),
      ],
      ),
    );
  }
}
