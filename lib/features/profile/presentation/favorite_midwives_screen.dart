import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/midwife_profile_detail_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/find_midwife_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/chat_screen.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/widgets/inner_page_app_bar.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class FavoriteMidwivesScreen extends StatefulWidget {
  const FavoriteMidwivesScreen({super.key});

  @override
  State<FavoriteMidwivesScreen> createState() => _FavoriteMidwivesScreenState();
}

class _FavoriteMidwivesScreenState extends State<FavoriteMidwivesScreen> {
  final _repository = MidwifeRepositoryImpl(MidwifeApiService());
  bool _isLoading = true;
  String? _errorMessage;
  List<MidwifeProfile> _favoriteMidwives = [];

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allMidwives = await _repository.getMidwives();
      if (mounted) {
        setState(() {
          _favoriteMidwives = allMidwives.where((m) => m.isFavorite).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load favorite midwives. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _confirmRemoveFavorite(MidwifeProfile midwife) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.favorite_rounded, color: Colors.red, size: 22),
              SizedBox(width: 8),
              Text(
                'Remove Favorite',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to remove ${midwife.fullName} from your saved midwives?',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                // Optimistic UI update
                setState(() {
                  _favoriteMidwives.removeWhere((m) => m.id == midwife.id);
                });

                try {
                  await _repository.toggleFavorite(midwife.id);
                  if (mounted) {
                    CustomSnackBar.show(context, message: 'Removed ${midwife.fullName} from saved midwives');
                  }
                } catch (e) {
                  if (mounted) {
                    _fetchFavorites(); // Re-sync on failure
                    CustomSnackBar.show(context, message: 'Failed to update favorite status', isError: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: const Text('Remove', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openMidwifeDetail(MidwifeProfile midwife) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MidwifeProfileDetailScreen(midwife: midwife),
      ),
    ).then((_) => _fetchFavorites());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildInnerPageAppBar(
        context,
        title: AppLocalizations.of(context)!.savedMidwives,
        showLanguage: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.orange),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchFavorites,
                          icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                          label: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchFavorites,
                  color: AppColors.primaryGreen,
                  child: _favoriteMidwives.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 100, left: 24, right: 24),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey.shade900 : const Color(0xFFF1F8E9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.favorite_border_rounded,
                                        size: 52,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'No Saved Midwives',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap the heart icon on any midwife profile to save them here for quick access and booking.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const FindMidwifeScreen(),
                                            ),
                                          ).then((_) => _fetchFavorites());
                                        },
                                        icon: const Icon(Icons.person_search_rounded, color: Colors.white, size: 20),
                                        label: Text(
                                          AppLocalizations.of(context)!.findAMidwife,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryGreen,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          itemCount: _favoriteMidwives.length,
                          itemBuilder: (context, index) {
                            final mw = _favoriteMidwives[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade900 : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _openMidwifeDetail(mw),
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header Row: Avatar, Name & Favorite Action
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 26,
                                              backgroundColor: const Color(0xFFE8F5E9),
                                              backgroundImage: mw.avatarUrl != null ? NetworkImage(mw.avatarUrl!) : null,
                                              child: mw.avatarUrl == null
                                                  ? const Icon(Icons.person, color: AppColors.primaryGreen, size: 28)
                                                  : null,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          mw.fullName,
                                                          style: TextStyle(
                                                            fontSize: 16.5,
                                                            fontWeight: FontWeight.bold,
                                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      const Icon(Icons.verified_rounded, color: AppColors.primaryGreen, size: 17),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    mw.specialty,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.primaryGreen,
                                                    ),
                                                  ),
                                                  if (mw.hospitalName.isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      mw.hospitalName,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () => _confirmRemoveFavorite(mw),
                                              tooltip: 'Remove Favorite',
                                              icon: const Icon(Icons.favorite_rounded, color: Colors.red, size: 22),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),

                                        // Badges Row: Rating, Experience & Consultation
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFF8E1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.star_rounded, color: AppColors.accentYellow, size: 15),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${mw.ratingAverage.toStringAsFixed(1)} (${mw.ratingCount})',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF5D4037),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8F5E9),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${mw.experienceYears}+ Yrs Exp',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryGreen,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        const Divider(height: 1),
                                        const SizedBox(height: 12),

                                        // Action Buttons Row (Book & Chat)
                                        Row(
                                          children: [
                                            Expanded(
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
                                                label: const Text('Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.primaryGreen,
                                                  side: const BorderSide(color: AppColors.primaryGreen),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _openMidwifeDetail(mw),
                                                icon: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 16),
                                                label: const Text('Book Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primaryGreen,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
