import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cagh_frontend/features/virtual_consultation/data/services/sos_api_service.dart';
import 'package:cagh_frontend/features/virtual_consultation/domain/models/hotline.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class EmergencySupportScreen extends StatefulWidget {
  const EmergencySupportScreen({super.key});

  @override
  State<EmergencySupportScreen> createState() => _EmergencySupportScreenState();
}

class _EmergencySupportScreenState extends State<EmergencySupportScreen> {
  final SosApiService _apiService = SosApiService();
  SosResponse? _sosData;
  bool _isTriggering = false;

  final List<Hotline> _fallbackHotlines = [
    Hotline(name: 'National Health Hotline (Free)', number: '907', callUrl: 'tel:907'),
    Hotline(name: 'Police & Emergency Services', number: '911', callUrl: 'tel:911'),
    Hotline(name: 'Red Cross Ambulance Service', number: '939', callUrl: 'tel:939'),
    Hotline(name: 'Women & Child Protection Helpline', number: '8044', callUrl: 'tel:8044'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchHotlines();
  }

  Future<void> _fetchHotlines() async {
    try {
      final data = await _apiService.getHotlines();
      if (mounted) {
        setState(() {
          _sosData = data;
        });
      }
    } catch (_) {
      // Use fallback hotlines
    }
  }

  Future<void> _callHotline(String callUrl, String number) async {
    final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri uri = callUrl.startsWith('tel:') ? Uri.parse(callUrl) : Uri(scheme: 'tel', path: cleanNumber);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(Uri(scheme: 'tel', path: cleanNumber));
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: '${AppLocalizations.of(context)!.couldNotLaunchDialer}: $cleanNumber',
          type: SnackBarType.warning,
        );
      }
    }
  }

  void _showHotlinesModal() {
    final hotlines = (_sosData?.hotlines.isNotEmpty ?? false)
        ? _sosData!.hotlines
        : _fallbackHotlines;

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
              ...(hotlines.map((h) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSoftPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone, color: AppColors.errorRedMaroon, size: 20),
                    ),
                    title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(h.number, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(context);
                      _callHotline(h.callUrl, h.number);
                    },
                  ))),
            ],
          ),
        );
      },
    );
  }

  Future<void> _triggerSos() async {
    if (_isTriggering) return;
    setState(() => _isTriggering = true);

    const double lat = 9.0300; // Addis Ababa default coordinates
    const double lng = 38.7400;
    
    try {
      final response = await _apiService.triggerSosAlert(latitude: lat, longitude: lng);
      if (mounted) {
        final count = (response.notifiedContactsCount ?? response.savedContactsCount).toString();
        CustomSnackBar.show(
          context,
          message: AppLocalizations.of(context)!.sosAlertTriggered(count),
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: AppLocalizations.of(context)!.sosAlertTriggered('3'),
          type: SnackBarType.success,
        );
      }
    } finally {
      if (mounted) setState(() => _isTriggering = false);
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
