import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_api_service.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/midwife_profile_detail_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/chat_screen.dart';
import 'package:cagh_frontend/features/appointments/presentation/screens/book_appointment_screen.dart';
import 'package:cagh_frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:cagh_frontend/shared/widgets/app_profile_avatar.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class ConsultHubScreen extends ConsumerStatefulWidget {
  final VoidCallback? onFindMidwifeTap;
  final bool isActive;
  final int initialSegment;

  const ConsultHubScreen({
    super.key,
    this.onFindMidwifeTap,
    this.isActive = false,
    this.initialSegment = 0,
  });

  @override
  ConsumerState<ConsultHubScreen> createState() => _ConsultHubScreenState();
}

class _ConsultHubScreenState extends ConsumerState<ConsultHubScreen> {
  // Brand tokens
  static const Color primaryGreen = AppColors.primaryGreen; // #315E26
  static const Color textDark = Color(0xFF142217); // Green-tinted near-black
  static const Color textSecondary = Color(0xFF617364); // Refined muted sage-grey
  static const Color borderLight = Color(0xFFE2E8E0); // Subtle natural separator
  static const Color surfaceWarm = Color(0xFFF8FAF7); // Soft sage-tinted surface

  // Segment index: 0 = Find a Midwife, 1 = Messages
  late int _selectedSegment;

  // Midwives data
  final MidwifeRepositoryImpl _midwifeRepository = MidwifeRepositoryImpl(MidwifeApiService());
  List<MidwifeProfile> _allMidwives = [];
  List<MidwifeProfile> _filteredMidwives = [];
  bool _isLoadingMidwives = true;
  String? _midwivesError;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  // Messages data
  bool _isLoadingRooms = false;
  String? _roomsError;
  List<Map<String, dynamic>> _chatRooms = [];
  Map<String, String> _midwifeNames = {};

  @override
  void initState() {
    super.initState();
    _selectedSegment = widget.initialSegment;
    _fetchMidwives();
    _fetchChatRooms();
  }

  @override
  void didUpdateWidget(covariant ConsultHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _fetchMidwives();
      _fetchChatRooms();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ================= DATA FETCHING =================

  Future<void> _fetchMidwives() async {
    setState(() {
      _isLoadingMidwives = true;
      _midwivesError = null;
    });

    try {
      final data = await _midwifeRepository.getMidwives(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      final verified = data.where((m) =>
          m.verificationStatus.toUpperCase() == 'APPROVED' ||
          m.verificationStatus.toUpperCase() == 'VERIFIED').toList();

      final list = verified.isNotEmpty ? verified : data;

      final namesMap = <String, String>{};
      for (var mw in data) {
        namesMap[mw.id.toString()] = mw.fullName.isNotEmpty ? mw.fullName : 'Midwife';
      }

      if (mounted) {
        setState(() {
          _allMidwives = list;
          _midwifeNames = namesMap;
          _applyFilters();
          _isLoadingMidwives = false;
        });
      }
    } catch (e, stack) {
      AppLogger.e('ConsultHubScreen: Error fetching midwives', e, stack);
      if (mounted) {
        setState(() {
          _midwivesError = 'Unable to load midwives. Please check your connection.';
          _isLoadingMidwives = false;
        });
      }
    }
  }

  void _applyFilters() {
    _filteredMidwives = _allMidwives.where((mw) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = mw.fullName.toLowerCase().contains(q);
        final matchesSpec = mw.specialty.toLowerCase().contains(q);
        final matchesHosp = mw.hospitalName.toLowerCase().contains(q);
        if (!matchesName && !matchesSpec && !matchesHosp) return false;
      }
      return true;
    }).toList();
  }

  void _onSearchChanged(String val) {
    setState(() => _searchQuery = val.trim());
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchMidwives();
    });
  }

  Future<void> _toggleFavorite(MidwifeProfile mw) async {
    final idx = _allMidwives.indexWhere((m) => m.id == mw.id);
    if (idx != -1) {
      final updated = MidwifeProfile(
        id: mw.id,
        userId: mw.userId,
        username: mw.username,
        firstName: mw.firstName,
        lastName: mw.lastName,
        email: mw.email,
        avatarUrl: mw.avatarUrl,
        hospitalId: mw.hospitalId,
        hospitalName: mw.hospitalName,
        hospitalAddress: mw.hospitalAddress,
        specialty: mw.specialty,
        experienceYears: mw.experienceYears,
        languages: mw.languages,
        bio: mw.bio,
        offeredConsultationTypes: mw.offeredConsultationTypes,
        ratingAverage: mw.ratingAverage,
        ratingCount: mw.ratingCount,
        isFavorite: !mw.isFavorite,
        isAcceptingBookings: mw.isAcceptingBookings,
        consultationFee: mw.consultationFee,
        verificationStatus: mw.verificationStatus,
      );

      setState(() {
        _allMidwives[idx] = updated;
        _applyFilters();
      });

      try {
        await _midwifeRepository.toggleFavorite(mw.id);
      } catch (_) {
        _fetchMidwives();
      }
    }
  }

  Future<void> _fetchChatRooms() async {
    setState(() {
      _isLoadingRooms = true;
      _roomsError = null;
    });

    try {
      final rooms = await ChatApiService.getChatRooms();
      final uniqueRooms = <String, Map<String, dynamic>>{};

      for (var room in rooms) {
        final mwId = _extractMidwifeId(room);
        if (!uniqueRooms.containsKey(mwId)) {
          uniqueRooms[mwId] = room;
        } else {
          final existingStatus = uniqueRooms[mwId]!['status'];
          final newStatus = room['status'];
          if (existingStatus == 'REQUESTED' && newStatus != 'REQUESTED') {
            uniqueRooms[mwId] = room;
          }
        }
      }

      if (mounted) {
        setState(() {
          _chatRooms = uniqueRooms.values.toList();
          _isLoadingRooms = false;
        });
        ref.read(notificationProvider.notifier).refreshNotifications();
      }
    } catch (e) {
      AppLogger.d('ConsultHubScreen: Error loading chat rooms: $e');
      if (mounted) {
        setState(() {
          _roomsError = 'Unable to load conversations.';
          _isLoadingRooms = false;
        });
      }
    }
  }

  String _extractMidwifeName(Map<String, dynamic> room) {
    final dynamic mwData = room['midwife_detail'] ?? room['midwife'];
    final dynamic mwUser = _mapPath('user', mwData);
    final dynamic mwProfile = _mapPath('profile', mwUser);

    if (mwProfile is Map) {
      final fName = mwProfile['first_name']?.toString() ?? '';
      final lName = mwProfile['last_name']?.toString() ?? '';
      if (fName.isNotEmpty || lName.isNotEmpty) return '$fName $lName'.trim();
    } else if (mwUser is Map) {
      final fName = mwUser['first_name']?.toString() ?? '';
      final lName = mwUser['last_name']?.toString() ?? '';
      if (fName.isNotEmpty || lName.isNotEmpty) return '$fName $lName'.trim();
      final name = mwUser['name']?.toString() ?? '';
      if (name.isNotEmpty) return name;
    } else if (mwData is Map) {
      final name = mwData['name'] ?? mwData['full_name'];
      if (name is String && name.isNotEmpty) return name;
    }

    final midwifeId = _extractMidwifeId(room);
    if (_midwifeNames.containsKey(midwifeId)) {
      return _midwifeNames[midwifeId]!;
    }

    return 'Midwife';
  }

  String _extractMidwifeId(Map<String, dynamic> room) {
    final dynamic mwData = room['midwife_detail'] ?? room['midwife'];
    if (mwData is Map) {
      final id = mwData['id'] ?? mwData['user_id'];
      if (id != null) return id.toString();
    } else if (mwData is String || mwData is int) {
      return mwData.toString();
    }
    return room['midwife_id']?.toString() ?? '';
  }

  dynamic _mapPath(String path, dynamic root) {
    if (root == null || root is! Map) return null;
    if (path.startsWith('#')) {
      final key = path.substring(1);
      return root[key] ?? _mapPath(key, root['user']) ?? _mapPath(key, root['profile']);
    }
    return root[path];
  }

  // ================= NAVIGATION ACTIONS =================

  void _openChatWithMidwife(MidwifeProfile mw) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          midwife: mw,
          midwifeId: mw.id.toString(),
          midwifeName: mw.fullName,
        ),
      ),
    ).then((_) {
      _fetchChatRooms();
      ref.read(notificationProvider.notifier).refreshNotifications();
    });
  }

  void _openChatWithRoom(Map<String, dynamic> room) {
    final midwifeId = _extractMidwifeId(room);
    final midwifeName = _extractMidwifeName(room);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoomId: room['id']?.toString(),
          midwifeId: midwifeId,
          midwifeName: midwifeName,
        ),
      ),
    ).then((_) {
      _fetchChatRooms();
      ref.read(notificationProvider.notifier).refreshNotifications();
    });
  }

  void _openBookingWithMidwife(MidwifeProfile mw) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookAppointmentScreen(midwife: mw),
      ),
    );
  }

  void _openMidwifeDetail(MidwifeProfile mw) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MidwifeProfileDetailScreen(midwife: mw),
      ),
    ).then((_) => _fetchMidwives());
  }

  // ================= AVATAR VISUAL PALETTE =================

  Color _getAvatarBg(String name, bool isDark) {
    if (isDark) {
      final darkTints = [
        const Color(0xFF352636),
        const Color(0xFF263335),
        const Color(0xFF332F23),
        const Color(0xFF243327),
        const Color(0xFF292638),
      ];
      return darkTints[name.hashCode.abs() % darkTints.length];
    }
    final lightTints = [
      const Color(0xFFFDE8E8), // Warm Rose
      const Color(0xFFFEF3C7), // Warm Amber
      const Color(0xFFE0E7FF), // Soft Indigo
      const Color(0xFFE8F5E9), // Mint Sage
      const Color(0xFFF3E8FF), // Gentle Lilac
      const Color(0xFFE0F2FE), // Soft Sky
    ];
    return lightTints[name.hashCode.abs() % lightTints.length];
  }

  Color _getAvatarTextColor(String name, bool isDark) {
    if (isDark) {
      final lightText = [
        const Color(0xFFFCA5A5),
        const Color(0xFF6EE7B7),
        const Color(0xFFFCD34D),
        const Color(0xFF86EFAC),
        const Color(0xFFC4B5FD),
      ];
      return lightText[name.hashCode.abs() % lightText.length];
    }
    final darkText = [
      const Color(0xFF9B1C1C),
      const Color(0xFF92400E),
      const Color(0xFF3730A3),
      const Color(0xFF1E5128),
      const Color(0xFF6B21A8),
      const Color(0xFF0369A1),
    ];
    return darkText[name.hashCode.abs() % darkText.length];
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  // ================= MAIN BUILD =================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;


    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Creative Hero Banner (Warm & Inspiring Maternal Card)
            _buildHeroBanner(isDark),

            // 2. Segmented Navigation: Find a Midwife / Messages
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSegmentedControl(isDark),
            ),

            const SizedBox(height: 10),

            // 3. Active Body View
            Expanded(
              child: _selectedSegment == 0
                  ? _buildFindMidwifeView(isDark)
                  : _buildMessagesView(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CREATIVE HERO BANNER =================

  Widget _buildHeroBanner(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E2E20), const Color(0xFF152217)]
                : [const Color(0xFFF1F8EE), const Color(0xFFE4F0E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2C452F) : const Color(0xFFD4E7D0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryGreen.withValues(alpha: isDark ? 0.4 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 11, color: primaryGreen),
                            const SizedBox(width: 4),
                            Text(
                              l10n.verifiedMaternalCare,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: isDark ? const Color(0xFF8FD883) : primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10n.certifiedMidwivesNetwork,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : textDark,
                      letterSpacing: -0.3,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.heroConsultGuidance,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: isDark ? AppColors.darkTextSecondary : textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF253B27) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: primaryGreen,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SEGMENTED CONTROL =================

  Widget _buildSegmentedControl(bool isDark) {
    final unreadCount = ref.watch(notificationProvider).unreadMessagesCount;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2B1E) : const Color(0xFFE8EFE6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2E4531) : const Color(0xFFD4E3D2),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Find a Midwife
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSegment = 0),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedSegment == 0
                      ? primaryGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedSegment == 0
                      ? [
                          BoxShadow(
                            color: primaryGreen.withValues(alpha: isDark ? 0.45 : 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      size: 17,
                      color: _selectedSegment == 0
                          ? Colors.white
                          : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475C4A)),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      l10n.findAMidwife,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: _selectedSegment == 0 ? FontWeight.w700 : FontWeight.w600,
                        color: _selectedSegment == 0
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475C4A)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Messages
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedSegment = 1);
                if (_chatRooms.isEmpty) _fetchChatRooms();
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedSegment == 1
                      ? primaryGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedSegment == 1
                      ? [
                          BoxShadow(
                            color: primaryGreen.withValues(alpha: isDark ? 0.45 : 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: _selectedSegment == 1
                          ? Colors.white
                          : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475C4A)),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      l10n.messages,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: _selectedSegment == 1 ? FontWeight.w700 : FontWeight.w600,
                        color: _selectedSegment == 1
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475C4A)),
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _selectedSegment == 1 ? Colors.white : primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _selectedSegment == 1 ? primaryGreen : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= FIND A MIDWIFE VIEW =================

  Widget _buildFindMidwifeView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Pill Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : surfaceWarm,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF7A8B7C),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: isDark ? AppColors.darkTextPrimary : textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.searchMidwivesHint,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF7A8B7C),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    color: const Color(0xFF7A8B7C),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Scrollable Body: Midwife Cards List directly
        Expanded(
          child: _isLoadingMidwives
              ? const Center(
                  child: CircularProgressIndicator(
                    color: primaryGreen,
                    strokeWidth: 2.5,
                  ),
                )
              : _midwivesError != null
                  ? RefreshIndicator(
                      onRefresh: _fetchMidwives,
                      color: primaryGreen,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 40),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 36, color: Colors.grey.shade400),
                                  const SizedBox(height: 10),
                                  Text(
                                    _midwivesError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13.5, color: textSecondary),
                                  ),
                                  const SizedBox(height: 14),
                                  TextButton(
                                    onPressed: _fetchMidwives,
                                    child: Text(l10n.retry, style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredMidwives.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _fetchMidwives,
                          color: primaryGreen,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 48),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Column(
                                    children: [
                                      Icon(Icons.person_search_outlined, size: 40, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        l10n.noMidwivesFound,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.tryAdjustingSearch,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13, color: textSecondary),
                                      ),
                                      if (_searchQuery.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        TextButton(
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _searchQuery = '';
                                              _applyFilters();
                                            });
                                          },
                                          child: Text(
                                            l10n.clearSearch,
                                            style: const TextStyle(
                                              color: primaryGreen,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchMidwives,
                          color: primaryGreen,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 2, 20, 140),
                            itemCount: _filteredMidwives.length,
                            itemBuilder: (context, index) {
                              final mw = _filteredMidwives[index];
                              return _buildMidwifeCard(mw, isDark);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  // ================= CREATIVE MIDWIFE CARD =================

  Widget _buildMidwifeCard(MidwifeProfile mw, bool isDark) {
    final hasPhoto = mw.avatarUrl != null && mw.avatarUrl!.trim().isNotEmpty;

    // Genuine metadata
    final double rating = mw.ratingAverage;
    final int expYears = mw.experienceYears;
    final String hospital = mw.hospitalName.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE4EDE2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B381A).withValues(alpha: isDark ? 0.24 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _openMidwifeDetail(mw),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar with verified badge (NO green dot), Name, Specialty & Favorite Heart
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Photo with verified badge only
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: _getAvatarBg(mw.fullName, isDark),
                          backgroundImage: hasPhoto ? NetworkImage(mw.avatarUrl!) : null,
                          child: !hasPhoto
                              ? Text(
                                  mw.fullName.isNotEmpty ? mw.fullName[0].toUpperCase() : 'M',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _getAvatarTextColor(mw.fullName, isDark),
                                  ),
                                )
                              : null,
                        ),
                        // Verified badge
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Midwife Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mw.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : textDark,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (mw.specialty.trim().isNotEmpty &&
                              mw.specialty.trim().toLowerCase() != 'maternal health specialist' &&
                              mw.specialty.trim().toLowerCase() != 'maternal health' &&
                              mw.specialty.trim().toLowerCase() != 'null') ...[
                            Container(
                              margin: const EdgeInsets.only(top: 2, bottom: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF213423) : const Color(0xFFEAF5E8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                mw.specialty.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: primaryGreen,
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              l10n.certifiedHealthcareMidwife,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7B6E),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Interactive Favorite Action
                    GestureDetector(
                      onTap: () => _toggleFavorite(mw),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: mw.isFavorite
                              ? const Color(0xFFFFECEF)
                              : (isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF4F7F3)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          mw.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 17,
                          color: mw.isFavorite ? const Color(0xFFE11D48) : const Color(0xFF8B9D8E),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Highlights Row: Hospital Tag (Prominent), Rating Tag, Experience Tag
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    // Hospital or Health Center Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2E20) : const Color(0xFFEEF6ED),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2C452E) : const Color(0xFFCFE4CC),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_hospital_rounded,
                            size: 12,
                            color: primaryGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hospital.isNotEmpty ? hospital : l10n.generalHealthCenter,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF90D985) : primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Rating Tag
                    if (rating > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF332B1E) : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: isDark ? const Color(0xFF4D3E28) : const Color(0xFFFED7AA),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('⭐ ', style: TextStyle(fontSize: 10)),
                            Text(
                              '${rating.toStringAsFixed(1)}${mw.ratingCount > 0 ? ' (${mw.ratingCount})' : ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Experience Tag
                    if (expYears > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F3022) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2F4733) : const Color(0xFFBBF7D0),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          l10n.yearsExp(expYears),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Subtle Separator
                Container(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : const Color(0xFFF0F5EE),
                ),

                const SizedBox(height: 10),

                // High-End Creative Action Buttons Pair
                Row(
                  children: [
                    // Secondary Companion Action: Message
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () => _openChatWithMidwife(mw),
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 15,
                            color: primaryGreen,
                          ),
                          label: Text(
                            l10n.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryGreen,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF1E2D20) : const Color(0xFFEDF6EC),
                            elevation: 0,
                            side: BorderSide(
                              color: isDark ? const Color(0xFF2C452E) : const Color(0xFFCFE4CC),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Primary CTA Action: Book Consultation (Gradient & Soft Elevation)
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryGreen, Color(0xFF3C7230)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: [
                              BoxShadow(
                                color: primaryGreen.withValues(alpha: isDark ? 0.35 : 0.22),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _openBookingWithMidwife(mw),
                            icon: const Icon(
                              Icons.calendar_month_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Book Visit',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                          ),
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
  }

  // ================= MESSAGES VIEW =================

  Widget _buildMessagesView(bool isDark) {
    if (_isLoadingRooms) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryGreen,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_roomsError != null) {
      return RefreshIndicator(
        onRefresh: _fetchChatRooms,
        color: primaryGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(Icons.info_outline_rounded, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(_roomsError!, style: const TextStyle(fontSize: 13.5, color: textSecondary)),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _fetchChatRooms,
                    child: Text(l10n.retry, style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_chatRooms.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchChatRooms,
        color: primaryGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noConversationsYet,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.startConsultationHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() => _selectedSegment = 0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        l10n.findAMidwife,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchChatRooms,
      color: primaryGreen,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        // 140px bottom padding guarantees clearance above floating nav and FABs
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
        itemCount: _chatRooms.length,
        separatorBuilder: (context, index) => Divider(
          color: isDark ? AppColors.darkBorder : const Color(0xFFF0F4EF),
          height: 1,
          thickness: 0.8,
        ),
        itemBuilder: (context, index) {
          final room = _chatRooms[index];
          final midwifeName = _extractMidwifeName(room);

          String lastMessage = 'Tap to open chat';
          String timeText = '';

          final latestMsg = room['latest_message'];
          if (latestMsg is Map) {
            final lmText = latestMsg['text'] ?? latestMsg['content'];
            if (lmText is String && lmText.isNotEmpty) lastMessage = lmText;
            final lmCreated = latestMsg['created_at'] ?? latestMsg['sent_at'];
            if (lmCreated is String) {
              try {
                final dt = DateTime.parse(lmCreated).toLocal();
                timeText = DateFormat('h:mm a').format(dt);
              } catch (_) {}
            }
          } else if (room['created_at'] is String) {
            try {
              final dt = DateTime.parse(room['created_at']).toLocal();
              timeText = DateFormat('MMM d').format(dt);
            } catch (_) {}
          }

          final int unreadCount = int.tryParse(room['unread_count']?.toString() ?? '') ?? 0;
          final bool hasUnread = unreadCount > 0;

          return InkWell(
            onTap: () => _openChatWithRoom(room),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  AppProfileAvatar(
                    radius: 22,
                    imageUrl: _mapPath('#avatar_url', room['midwife_detail']) ?? _mapPath('#avatar_url', room['midwife']),
                    name: midwifeName,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                midwifeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                  color: isDark ? AppColors.darkTextPrimary : textDark,
                                ),
                              ),
                            ),
                            if (timeText.isNotEmpty)
                              Text(
                                timeText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hasUnread
                                      ? primaryGreen
                                      : (isDark ? AppColors.darkTextSecondary : const Color(0xFF8A9B8D)),
                                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: hasUnread
                                      ? (isDark ? AppColors.darkTextPrimary : textDark)
                                      : (isDark ? AppColors.darkTextSecondary : textSecondary),
                                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (hasUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: primaryGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
