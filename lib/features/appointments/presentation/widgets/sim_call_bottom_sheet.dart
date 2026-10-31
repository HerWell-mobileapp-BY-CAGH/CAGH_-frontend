import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/services/consultation_api_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class SimCallBottomSheet extends StatefulWidget {
  final Appointment appointment;
  final bool isMidwifeCalling;

  const SimCallBottomSheet({
    super.key,
    required this.appointment,
    this.isMidwifeCalling = false,
  });

  static Future<void> show(
    BuildContext context,
    Appointment appointment, {
    bool isMidwifeCalling = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SimCallBottomSheet(
        appointment: appointment,
        isMidwifeCalling: isMidwifeCalling,
      ),
    );
  }

  @override
  State<SimCallBottomSheet> createState() => _SimCallBottomSheetState();
}

class _SimCallBottomSheetState extends State<SimCallBottomSheet> {
  final AppointmentApiService _appointmentApiService = AppointmentApiService();
  final ConsultationApiService _consultationApiService = ConsultationApiService();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _eligibilityData;

  @override
  void initState() {
    super.initState();
    _loadCallEligibility();
  }

  Future<void> _loadCallEligibility() async {
    // If appointment already has eligibility attached from list fetch, preload it
    if (widget.appointment.callEligibility != null) {
      _eligibilityData = widget.appointment.callEligibility;
    }

    try {
      // 1. Fetch fresh real-time call eligibility from backend
      Map<String, dynamic>? res;
      try {
        res = await _appointmentApiService.getCallAccess(widget.appointment.appointmentId);
      } catch (e) {
        AppLogger.d('[SIM CALL] Appointment call-access error: $e, trying consultation fallback');
        // Fallback to consultation endpoint if appointment-level route failed
        try {
          final consultData = await _consultationApiService
              .getConsultationByAppointment(widget.appointment.appointmentId);
          final consultId = consultData['id']?.toString() ?? widget.appointment.appointmentId;
          res = await _consultationApiService.getCallAccess(consultId);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          if (res != null) {
            _eligibilityData = res;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.d('[SIM CALL] Failed to load call eligibility: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // If we had preloaded data, keep it; otherwise show error message
          if (_eligibilityData == null) {
            _errorMessage = e.toString().replaceAll('Exception: ', '').trim();
          }
        });
      }
    }
  }

  String _formatPhoneNumber(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+251') && digits.length == 13) {
      return '${digits.substring(0, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 9)} ${digits.substring(9)}';
    } else if (digits.startsWith('0') && digits.length == 10) {
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    }
    return raw;
  }

  String _detectCarrier(String? phone, String? carrierFromBackend) {
    if (carrierFromBackend != null && carrierFromBackend.isNotEmpty) {
      return carrierFromBackend;
    }
    if (phone == null || phone.isEmpty) return 'Mobile Network';
    final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.contains('9') && (clean.startsWith('09') || clean.startsWith('2519'))) {
      return 'Ethio Telecom';
    }
    if (clean.contains('7') && (clean.startsWith('07') || clean.startsWith('2517'))) {
      return 'Safaricom Ethiopia';
    }
    return 'Mobile Network';
  }

  Future<void> _makeDirectCall(String telNumber) async {
    HapticFeedback.mediumImpact();
    final cleanNumber = telNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(Uri(scheme: 'tel', path: cleanNumber));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      AppLogger.d('[SIM CALL] Error launching dialer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open phone dialer for: $cleanNumber'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Copied $text to clipboard'),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final apt = widget.appointment;
    final l10n = AppLocalizations.of(context);

    // Resolve target person details
    final String targetDisplayName;
    final String targetRole;
    if (widget.isMidwifeCalling) {
      targetDisplayName = (apt.userFullName != null &&
              apt.userFullName!.trim().isNotEmpty &&
              apt.userFullName!.trim().toLowerCase() != 'recipient')
          ? apt.userFullName!.trim()
          : (l10n?.patient ?? 'Patient');
      targetRole = l10n?.patient ?? 'Patient';
    } else {
      targetDisplayName = (apt.midwifeName != null &&
              apt.midwifeName!.trim().isNotEmpty &&
              apt.midwifeName!.trim().toLowerCase() != 'recipient')
          ? apt.midwifeName!.trim()
          : 'Health Professional';
      targetRole = l10n?.certifiedMidwife ?? 'Certified Health Professional';
    }

    // Resolve eligibility values
    final bool canCallFromBackend = _eligibilityData?['can_call'] == true;
    final bool isWindowActive = _eligibilityData?['is_call_window_active'] == true;
    final String windowState = _eligibilityData?['window_state']?.toString() ?? 'UNKNOWN';

    // Phone number resolution
    String? resolvedPhone = _eligibilityData?['phone_number_local'] ??
        _eligibilityData?['phone_number'];
    
    // Fallback for midwife calling patient directly
    if (widget.isMidwifeCalling && (resolvedPhone == null || resolvedPhone.isEmpty)) {
      resolvedPhone = apt.patientPhone;
    }
    // Fallback for patient calling midwife if available in appointment model
    if (!widget.isMidwifeCalling && (resolvedPhone == null || resolvedPhone.isEmpty)) {
      resolvedPhone = apt.midwifePhone;
    }

    final bool canCallFinal = canCallFromBackend ||
        (widget.isMidwifeCalling && resolvedPhone != null && resolvedPhone.isNotEmpty && apt.status == AppointmentStatus.confirmed);

    final String carrier = _detectCarrier(resolvedPhone, _eligibilityData?['carrier']?.toString());
    final String start12h = _eligibilityData?['start_time_12h']?.toString() ?? apt.startTime;
    final String end12h = _eligibilityData?['end_time_12h']?.toString() ?? apt.endTime;
    final String backendMessage = _eligibilityData?['message']?.toString() ?? '';

    final initials = targetDisplayName.trim().isNotEmpty
        ? targetDisplayName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : (widget.isMidwifeCalling ? 'P' : 'M');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181F1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Avatar, Name, Certified Badge
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2C5927), const Color(0xFF1E3A1A)]
                        : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.35),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFA5D6A7) : AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            targetDisplayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: AppColors.primaryGreen, size: 18),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          targetRole,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1F3824) : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sim_card_outlined, size: 11, color: isDark ? const Color(0xFF81C784) : AppColors.primaryGreen),
                              const SizedBox(width: 3),
                              Text(
                                'SIM Cellular',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF81C784) : AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: isDark ? Colors.grey.shade400 : const Color(0xFF94A3B8)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (_isLoading) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222C24) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Verifying scheduled call window...',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            if (_errorMessage != null) ...[
              _buildErrorBanner(isDark: isDark, message: _errorMessage!),
              const SizedBox(height: 14),
            ],
            // Status Card (Active Window vs Scheduled/Expired)
            _buildWindowStatusCard(
              isDark: isDark,
              isWindowActive: isWindowActive,
              canCall: canCallFinal,
              windowState: windowState,
              start12h: start12h,
              end12h: end12h,
              backendMessage: backendMessage,
            ),

            const SizedBox(height: 14),

            // Phone Number Card
            if (resolvedPhone != null && resolvedPhone.isNotEmpty) ...[
              _buildPhoneNumberCard(
                isDark: isDark,
                phone: resolvedPhone,
                carrier: carrier,
              ),
              const SizedBox(height: 14),
            ],

            // SIM Privacy & Cellular Notice
            _buildCellularNotice(isDark: isDark),

            const SizedBox(height: 20),

            // Action Buttons
            if (canCallFinal && resolvedPhone != null && resolvedPhone.isNotEmpty) ...[
              ElevatedButton.icon(
                onPressed: () => _makeDirectCall(resolvedPhone!),
                icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
                label: Text(
                  'Call via $carrier',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  elevation: 2,
                  shadowColor: AppColors.primaryGreen.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.lock_clock_rounded, size: 18),
                label: Text(
                  windowState == 'BEFORE_WINDOW'
                      ? 'Available during call window ($start12h EAT)'
                      : 'Call Window Inactive',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                  disabledForegroundColor: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ],

          const SizedBox(height: 10),

          // Secondary Close Button
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowStatusCard({
    required bool isDark,
    required bool isWindowActive,
    required bool canCall,
    required String windowState,
    required String start12h,
    required String end12h,
    required String backendMessage,
  }) {
    if (canCall || isWindowActive) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E3522) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2E6B37) : const Color(0xFFBBF7D0),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x6622C55E),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Call Window Active Now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    backendMessage.isNotEmpty
                        ? backendMessage
                        : 'Active until $end12h EAT. Tap to place phone call directly via SIM.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF166534),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (windowState == 'BEFORE_WINDOW') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2415) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF6B531E) : const Color(0xFFFDE68A),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Call Window Not Yet Open',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Scheduled for $start12h – $end12h EAT. Direct cellular calling will become active once the appointment window begins.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF92400E),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Expired or other status
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF24272A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scheduled Window: $start12h – $end12h EAT',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  backendMessage.isNotEmpty
                      ? backendMessage
                      : 'The scheduled window for this appointment is not currently active.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberCard({
    required bool isDark,
    required String phone,
    required String carrier,
  }) {
    final formattedPhone = _formatPhoneNumber(phone);
    final isEthioTelecom = carrier.toLowerCase().contains('ethio');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2820) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF263829) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.phone_iphone_rounded, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isEthioTelecom
                            ? (isDark ? const Color(0xFF1B3D23) : const Color(0xFFE8F5E9))
                            : (isDark ? const Color(0xFF3D1B1B) : const Color(0xFFFFEBEE)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        carrier,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isEthioTelecom ? AppColors.primaryGreen : const Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  formattedPhone,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy Number',
            icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
            onPressed: () => _copyToClipboard(phone),
          ),
        ],
      ),
    );
  }

  Widget _buildCellularNotice({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A221C) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 15, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Direct SIM Call: Opens your phone dialer directly. Standard mobile network carrier rates apply.',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner({required bool isDark, required String message}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF331D1D) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _loadCallEligibility();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

