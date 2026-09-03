import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cagh_frontend/features/virtual_consultation/data/services/sos_api_service.dart';
import 'package:cagh_frontend/features/virtual_consultation/domain/models/hotline.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class EmergencySupportScreen extends StatefulWidget {
  const EmergencySupportScreen({super.key});

  @override
  State<EmergencySupportScreen> createState() => _EmergencySupportScreenState();
}

class _EmergencySupportScreenState extends State<EmergencySupportScreen> {
  final SosApiService _apiService = SosApiService();
  SosResponse? _sosData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHotlines();
  }

  Future<void> _fetchHotlines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _apiService.getHotlines();
      setState(() {
        _sosData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load emergency data.';
        _isLoading = false;
      });
    }
  }

  Future<void> _callHotline(String callUrl) async {
    final Uri uri = Uri.parse(callUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotLaunchDialer)),
        );
      }
    }
  }

  void _showHotlinesModal() {
    if (_sosData == null || _sosData!.hotlines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noHotlinesAvailable)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppLocalizations.of(context)!.hotlines,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              ...(_sosData!.hotlines.map((h) => ListTile(
                    leading: const Icon(Icons.phone, color: AppColors.errorRedMaroon),
                    title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(h.number),
                    onTap: () {
                      Navigator.pop(context);
                      _callHotline(h.callUrl);
                    },
                  ))),
            ],
          ),
        );
      },
    );
  }

  Future<void> _triggerSos() async {
    // For now, we use default/empty coordinates as geolocator is not set up
    // In future, integrate geolocator to fetch real coordinates
    const double lat = 0.0;
    const double lng = 0.0;
    
    try {
      final response = await _apiService.triggerSosAlert(latitude: lat, longitude: lng);
      if (mounted) {
        final count = (response.notifiedContactsCount ?? response.savedContactsCount ?? 0).toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.sosAlertTriggered(count))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToTriggerSos)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundRedPale,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 80,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: const TextStyle(
              color: AppColors.errorRedMaroon,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(context)!.emergency,
          style: const TextStyle(
            color: AppColors.errorRedMaroon,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                AppLocalizations.of(context)!.areYouOkay,
                style: const TextStyle(
                  color: AppColors.errorRedDeep,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.lifeThreateningEmergency,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.errorRedDark,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 50),
              
              // SOS Button
              GestureDetector(
                onTap: _triggerSos,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE53935).withValues(alpha: 0.5), // Outer ring
                  ),
                  child: Center(
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFB71C1C), // Inner circle
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.sos,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              
              // Call Emergency Services Card
              _buildActionCard(
                icon: Icons.phone,
                iconBgColor: AppColors.backgroundSoftPink,
                iconColor: AppColors.errorRedDark,
                title: AppLocalizations.of(context)!.emergencyHotline,
                subtitle: _sosData != null && _sosData!.primaryHotlineNumber.isNotEmpty
                    ? 'Primary: ${_sosData!.primaryHotlineNumber}'
                    : AppLocalizations.of(context)!.callAmbulance,
                onTap: _showHotlinesModal,
              ),
              
              const SizedBox(height: 16),
              
              // Notify Contacts Card
              _buildActionCard(
                icon: Icons.group,
                iconBgColor: AppColors.lightGreen,
                iconColor: AppColors.accentGreenDark,
                title: AppLocalizations.of(context)!.emergencyContactsList,
                subtitle: _sosData != null 
                    ? 'Send alert to ${_sosData!.savedContactsCount} contacts'
                    : AppLocalizations.of(context)!.useSosButton,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.useSosButton)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryGreen, width: 1.0), // Dark green border
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
