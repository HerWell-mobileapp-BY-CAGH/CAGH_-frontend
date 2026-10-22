import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/features/hotline/data/services/sos_api_service.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class HotlineItem {
  final String title;
  final String subtitle;
  final String number;
  final String callUrl;
  final String category;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const HotlineItem({
    required this.title,
    required this.subtitle,
    required this.number,
    required this.callUrl,
    required this.category,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class EmergencySupportScreen extends StatefulWidget {
  const EmergencySupportScreen({super.key});

  @override
  State<EmergencySupportScreen> createState() => _EmergencySupportScreenState();
}

class _EmergencySupportScreenState extends State<EmergencySupportScreen> {
  final SosApiService _apiService = SosApiService();
  Position? _currentPosition;
  bool _locationReady = false;
  bool _isSharingLocation = false;
  bool _isRefreshingLocation = false;
  String _selectedCategoryKey = 'All';

  static const String _caghHotlineNumber = '0996717744';
  static const String _caghHotlineDisplay = '0996 71 77 44';

  final List<HotlineItem> _staticHotlines = const [
    HotlineItem(
      title: 'National Ambulance & Health',
      subtitle: 'Free emergency & urgent health response (24/7)',
      number: '907',
      callUrl: 'tel:907',
      category: 'Medical',
      icon: Icons.medical_services_rounded,
      color: AppColors.errorRedDark,
      bgColor: Color(0xFFFEE2E2),
    ),
    HotlineItem(
      title: 'Police & Security Services',
      subtitle: 'National emergency security response',
      number: '911',
      callUrl: 'tel:911',
      category: 'Security',
      icon: Icons.local_police_rounded,
      color: Color(0xFF1D4ED8),
      bgColor: Color(0xFFDBEAFE),
    ),
    HotlineItem(
      title: 'Red Cross Ambulance',
      subtitle: 'Emergency first aid and patient transport',
      number: '939',
      callUrl: 'tel:939',
      category: 'Medical',
      icon: Icons.emergency_rounded,
      color: Color(0xFFDC2626),
      bgColor: Color(0xFFFEF2F2),
    ),
    HotlineItem(
      title: 'Women & Child Protection',
      subtitle: 'Helpline for adolescent girls & youth support',
      number: '8044',
      callUrl: 'tel:8044',
      category: 'Support',
      icon: Icons.shield_rounded,
      color: Color(0xFF7C3AED),
      bgColor: Color(0xFFF3E8FF),
    ),
    HotlineItem(
      title: 'Public Health Advisory (EPHI)',
      subtitle: 'National disease & health advisory helpline',
      number: '8335',
      callUrl: 'tel:8335',
      category: 'Medical',
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFF047857),
      bgColor: Color(0xFFD1FAE5),
    ),
    HotlineItem(
      title: 'Fire & Rescue Services',
      subtitle: 'Civil emergency, fire and disaster response',
      number: '991',
      callUrl: 'tel:991',
      category: 'Security',
      icon: Icons.fire_extinguisher_rounded,
      color: Color(0xFFEA580C),
      bgColor: Color(0xFFFFEDD5),
    ),
  ];

  List<HotlineItem> _hotlines = [];

  @override
  void initState() {
    super.initState();
    _hotlines = List.from(_staticHotlines);
    _checkLocation();
    _fetchDynamicHotlines();
  }

  Future<void> _checkLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 4),
            );
        if (mounted) {
          setState(() {
            _currentPosition = pos;
            _locationReady = true;
          });
        }
      } else {
        if (mounted) {
          setState(() => _locationReady = true);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _locationReady = true);
      }
    }
  }

  Future<void> _refreshLocation() async {
    if (_isRefreshingLocation) return;
    setState(() => _isRefreshingLocation = true);
    HapticFeedback.lightImpact();

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 6),
        );
        if (mounted) {
          setState(() {
            _currentPosition = pos;
            _locationReady = true;
          });
          final isAm = Localizations.localeOf(context).languageCode == 'am';
          CustomSnackBar.show(
            context,
            message: isAm ? 'የጂፒኤስ መገኛ ቦታ ታድሷል!' : 'GPS location updated!',
            type: SnackBarType.success,
          );
        }
      } else {
        if (mounted) {
          final isAm = Localizations.localeOf(context).languageCode == 'am';
          CustomSnackBar.show(
            context,
            message: isAm
                ? 'ለትክክለኛ መገኛ ቦታ የጂፒኤስ ፈቃድ ያስፈልጋል።'
                : 'Location permission needed for accurate GPS coordinates.',
            type: SnackBarType.warning,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        final isAm = Localizations.localeOf(context).languageCode == 'am';
        CustomSnackBar.show(
          context,
          message: isAm ? 'የመገኛ ቦታን ማግኘት አልተቻለም።' : 'Unable to refresh GPS coordinates right now.',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshingLocation = false);
      }
    }
  }

  Future<void> _fetchDynamicHotlines() async {
    try {
      final data = await _apiService.getHotlines();
      if (mounted && data.hotlines.isNotEmpty) {
        setState(() {
          for (final h in data.hotlines) {
            final exists = _hotlines.any((item) => item.number == h.number);
            if (!exists && h.number.isNotEmpty && h.number != _caghHotlineNumber) {
              _hotlines.add(
                HotlineItem(
                  title: h.name,
                  subtitle: 'Toll-free helpline (${h.number})',
                  number: h.number,
                  callUrl: h.callUrl.isNotEmpty ? h.callUrl : 'tel:${h.number}',
                  category: 'Support',
                  icon: Icons.phone_in_talk_rounded,
                  color: AppColors.primaryGreen,
                  bgColor: const Color(0xFFE8F5E9),
                ),
              );
            }
          }
        });
      }
    } catch (_) {
      // Keep static verified hotlines
    }
  }

  Future<void> _callHotline(String callUrl, String number) async {
    HapticFeedback.mediumImpact();
    final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri uri = callUrl.startsWith('tel:')
        ? Uri.parse(callUrl)
        : Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(Uri(scheme: 'tel', path: cleanNumber));
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        CustomSnackBar.show(
          context,
          message: '${l10n?.couldNotLaunchDialer ?? "Could not open dialer"}: $cleanNumber',
          type: SnackBarType.warning,
        );
      }
    }
  }

  Future<void> _shareLocationToHotline() async {
    if (_isSharingLocation) return;
    HapticFeedback.heavyImpact();
    setState(() => _isSharingLocation = true);

    try {
      // 1. Ensure location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            final isAm = Localizations.localeOf(context).languageCode == 'am';
            CustomSnackBar.show(
              context,
              message: isAm ? 'መገኛ ቦታን ለማጋራት የጂፒኤስ ፈቃድ ያስፈልጋል።' : 'Location permission is required to send your coordinates.',
              type: SnackBarType.warning,
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          final isAm = Localizations.localeOf(context).languageCode == 'am';
          CustomSnackBar.show(
            context,
            message: isAm ? 'የመገኛ ቦታ ፈቃድ ተከልክሏል። እባክዎ በስልክዎ ማስተካከያ ውስጥ ይፍቀዱ።' : 'Location permission is permanently denied. Please enable it in Settings.',
            type: SnackBarType.error,
          );
        }
        return;
      }

      // 2. Fetch fresh high-accuracy position
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 7),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos != null && mounted) {
        setState(() {
          _currentPosition = pos;
          _locationReady = true;
        });
      }

      final double? lat = pos?.latitude;
      final double? lng = pos?.longitude;

      // Clean coordinate string without any extra text
      final String cleanCoords = (lat != null && lng != null)
          ? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
          : '8.8866, 38.8113';

      final String mapsLink = (lat != null && lng != null)
          ? 'https://maps.google.com/?q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}'
          : 'https://maps.google.com/?q=8.8866,38.8113';

      final bool isAm = mounted && Localizations.localeOf(context).languageCode == 'am';

      final String dispatchText = isAm
          ? '🚨 አስቸኳይ የሲኤጂኤች የአደጋ ጊዜ ጥሪ\n'
            'ለታዳጊ ሴት አስቸኳይ ክሊኒካዊ ድጋፍ ያስፈልጋል!\n'
            '• መገኛ ቦታ (GPS): $cleanCoords\n'
            '• ካርታ (Google Maps): $mapsLink\n'
            'እባክዎ አፋጣኝ ድጋፍ ይላኩ።'
          : '🚨 URGENT CAGH ADOLESCENT EMERGENCY DISPATCH\n'
            'Urgent clinical assistance needed for adolescent girl!\n'
            '• GPS Coordinates: $cleanCoords\n'
            '• Google Maps Pin: $mapsLink\n'
            'Please dispatch emergency guidance / assistance immediately.';

      // 3. Trigger backend SOS notification & alert in background
      if (lat != null && lng != null) {
        try {
          await _apiService.triggerSosAlert(latitude: lat, longitude: lng);
        } catch (_) {}
      }

      // 4. Copy ONLY the clean coordinates to clipboard
      await Clipboard.setData(ClipboardData(text: cleanCoords));

      // 5. Open SMS directly addressed to 0996717744
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: _caghHotlineNumber,
        queryParameters: <String, String>{
          'body': dispatchText,
        },
      );

      bool launched = false;
      try {
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          launched = true;
        } else {
          final fallbackUri = Uri.parse(
            'sms:$_caghHotlineNumber?body=${Uri.encodeComponent(dispatchText)}',
          );
          if (await canLaunchUrl(fallbackUri)) {
            await launchUrl(fallbackUri);
            launched = true;
          }
        }
      } catch (_) {}

      if (mounted) {
        if (launched) {
          CustomSnackBar.show(
            context,
            message: isAm
                ? 'የመገኛ ቦታ መረጃ ወደ $_caghHotlineDisplay ተልኳል እንዲሁም ተቀድቷል!'
                : 'Location dispatched to $_caghHotlineDisplay and copied to clipboard!',
            type: SnackBarType.success,
          );
        } else {
          CustomSnackBar.show(
            context,
            message: isAm
                ? 'የጂፒኤስ መገኛ ($cleanCoords) ተቀድቷል! ለ$_caghHotlineDisplay መላክ ይችላሉ።'
                : 'Emergency GPS coordinates ($cleanCoords) copied to clipboard for $_caghHotlineDisplay!',
            type: SnackBarType.info,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Error sharing location: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharingLocation = false);
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text));
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(isAm ? '$text ተቀድቷል' : 'Copied $label: $text'),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Pure copyable GPS coordinates WITHOUT any "(GPS Ready)" text
  String get _locationCoordinateString {
    if (_currentPosition != null) {
      return '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}';
    }
    return _locationReady ? '8.8866, 38.8113' : '...';
  }

  String _getCategoryLabel(String key, AppLocalizations? l10n) {
    switch (key) {
      case 'All':
        return l10n?.categoryAll ?? 'All';
      case 'Medical':
        return l10n?.categoryMedical ?? 'Medical';
      case 'Security':
        return l10n?.categorySecurity ?? 'Security';
      case 'Support':
        return l10n?.categorySupport ?? 'Support';
      default:
        return key;
    }
  }

  String _getHotlineTitle(HotlineItem item, AppLocalizations? l10n) {
    switch (item.number) {
      case '907':
        return l10n?.nationalAmbulanceTitle ?? item.title;
      case '911':
        return l10n?.policeSecurityTitle ?? item.title;
      case '939':
        return l10n?.redCrossTitle ?? item.title;
      case '8044':
        return l10n?.womenChildTitle ?? item.title;
      case '8335':
        return l10n?.publicHealthTitle ?? item.title;
      case '991':
        return l10n?.fireRescueTitle ?? item.title;
      default:
        return item.title;
    }
  }

  String _getHotlineSubtitle(HotlineItem item, AppLocalizations? l10n) {
    switch (item.number) {
      case '907':
        return l10n?.nationalAmbulanceSubtitle ?? item.subtitle;
      case '911':
        return l10n?.policeSecuritySubtitle ?? item.subtitle;
      case '939':
        return l10n?.redCrossSubtitle ?? item.subtitle;
      case '8044':
        return l10n?.womenChildSubtitle ?? item.subtitle;
      case '8335':
        return l10n?.publicHealthSubtitle ?? item.subtitle;
      case '991':
        return l10n?.fireRescueSubtitle ?? item.subtitle;
      default:
        return item.subtitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isAm = Localizations.localeOf(context).languageCode == 'am';

    final filteredHotlines = _selectedCategoryKey == 'All'
        ? _hotlines
        : _hotlines.where((h) => h.category == _selectedCategoryKey).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101612) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF161F18) : Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 50,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222E25) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2E3D31) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primaryGreen, size: 14),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n?.emergencyHotlines ?? (isAm ? 'የአደጋ ጊዜ መስመሮች' : 'Emergency Hotlines'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F3824) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 12),
                const SizedBox(width: 4),
                Text(
                  l10n?.tollFree ?? (isAm ? 'ነጻ ጥሪ' : 'Toll-Free'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visually Premium Primary CAGH Emergency Hotline Card (0996717744) - Overflow-safe
              _buildCaghEmergencyHotlineCard(isDark, l10n),

              const SizedBox(height: 12),

              // Location Banner with Clean Pure Coordinates (No GPS ready text)
              _buildLocationBanner(isDark, l10n),

              const SizedBox(height: 16),

              // Section Header & Category Filter Tabs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n?.nationalEmergencyServices ?? (isAm ? 'ብሔራዊ የአደጋ ጊዜ አገልግሎቶች' : 'National Emergency Services'),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2A20) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${filteredHotlines.length} ${isAm ? 'መስመሮች' : 'lines'}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Category Selector Tabs
              _buildCategoryTabs(isDark, l10n),

              const SizedBox(height: 14),

              // Hotline Cards List (Clean, premium & overflow-safe)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredHotlines.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _buildHotlineCard(isDark, filteredHotlines[index], l10n);
                },
              ),

              const SizedBox(height: 16),

              // Informational Notice Banner
              _buildEmergencyNotice(isDark, l10n),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Visually Premium CAGH Emergency Hotline Card (0996717744) - Mathematically Overflow-Proof
  Widget _buildCaghEmergencyHotlineCard(bool isDark, AppLocalizations? l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF132B1A), const Color(0xFF0F2215)]
              : [const Color(0xFF1E4D2B), const Color(0xFF286A3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2E633C)
              : const Color(0xFF4ADE80).withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D2B).withOpacity(isDark ? 0.35 : 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Badges Row: Wrapped with Expanded and Flexible to avoid any pixel overflow
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF4ADE80),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n?.caghEmergencyHotlineBadge ?? 'CAGH EMERGENCY • 24/7',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD22B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD22B).withOpacity(0.4)),
                ),
                child: Text(
                  l10n?.priorityBadge ?? 'PRIORITY',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFD22B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Hotline Number Presentation
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                ),
                child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.adolescentEmergencyHelpline ?? 'Adolescent Emergency Helpline',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFA7F3D0),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            _caghHotlineDisplay,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _copyToClipboard(_caghHotlineNumber, 'Hotline Number'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.copy_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Concise, adolescent-focused description
          Text(
            l10n?.caghHotlineDescAdolescent ??
                '24/7 confidential helpline for adolescent girls facing acute health emergencies, sudden pain, or needing urgent clinical guidance.',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withOpacity(0.92),
              height: 1.38,
            ),
          ),

          const SizedBox(height: 16),

          // Primary Actions: Call Now and Share Location
          Row(
            children: [
              // Call Now Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callHotline('tel:$_caghHotlineNumber', _caghHotlineNumber),
                  icon: const Icon(Icons.call_rounded, size: 18, color: Color(0xFF1B4D2B)),
                  label: Text(
                    l10n?.callNowAction ?? 'Call Now',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4D2B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1B4D2B),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Share Location to Hotline Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSharingLocation ? null : _shareLocationToHotline,
                  icon: _isSharingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.share_location_rounded, color: Colors.white, size: 18),
                  label: Text(
                    _isSharingLocation
                        ? (l10n?.locatingAction ?? 'Locating...')
                        : (l10n?.shareLocationAction ?? 'Share Location'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.18),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.white.withOpacity(0.32)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Location card: pure copyable coordinates WITHOUT any "(GPS Ready)" text
  Widget _buildLocationBanner(bool isDark, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF19231B) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF263D2B) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF25402D) : const Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _locationReady ? Icons.my_location_rounded : Icons.location_searching_rounded,
              size: 16,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.yourLocationTitle ?? 'Your Location',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _locationCoordinateString, // Pure clean coordinates, e.g. "8.8866, 38.8113"
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF14532D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: _isRefreshingLocation
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
                  )
                : const Icon(Icons.refresh_rounded, size: 17, color: AppColors.primaryGreen),
            onPressed: _refreshLocation,
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primaryGreen),
            onPressed: () => _copyToClipboard(
              _locationCoordinateString,
              l10n?.yourLocationTitle ?? 'coordinates',
            ),
          ),
        ],
      ),
    );
  }

  // Category filter chips
  Widget _buildCategoryTabs(bool isDark, AppLocalizations? l10n) {
    final categoryKeys = ['All', 'Medical', 'Security', 'Support'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categoryKeys.map((key) {
          final isSelected = _selectedCategoryKey == key;
          final label = _getCategoryLabel(key, l10n);

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategoryKey = key),
              selectedColor: isDark ? AppColors.primaryGreen : const Color(0xFF0F172A),
              backgroundColor: isDark ? const Color(0xFF1E2820) : const Color(0xFFF1F5F9),
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade400 : const Color(0xFF475569)),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? const Color(0xFF2C3E30) : const Color(0xFFE2E8F0)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Clean, visually premium hotline card with direct call action
  Widget _buildHotlineCard(bool isDark, HotlineItem item, AppLocalizations? l10n) {
    final title = _getHotlineTitle(item, l10n);
    final subtitle = _getHotlineSubtitle(item, l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A221C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF27362B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? item.color.withOpacity(0.18) : item.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 12),

          // Titles & Number Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? item.color.withOpacity(0.2) : item.bgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.number,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: item.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Direct Call Action Button
          Material(
            color: item.color,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _callHotline(item.callUrl, item.number),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.call_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      l10n?.callNow ?? 'Call',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Friendly carrier and rate notice
  Widget _buildEmergencyNotice(bool isDark, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172019) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n?.emergencyLinesNotice ??
                  'All national emergency lines listed are toll-free and accessible 24/7 without credit across Ethio Telecom and Safaricom networks. For CAGH Hotline (0996 71 77 44), standard mobile rates or toll-free assistance applies.',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
