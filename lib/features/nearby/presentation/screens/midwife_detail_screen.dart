import 'package:flutter/material.dart';
import '../../domain/entities/healthcare_facility.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'midwife_booking_screen.dart';

class MidwifeDetailScreen extends StatelessWidget {
  final HealthcareFacility facility;

  const MidwifeDetailScreen({super.key, required this.facility});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF385A2E);
    final buttonGreen = isDark ? AppColors.darkButtonGreen : const Color(0xFF385A2E);
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF182335);
    final textSecondary = isDark ? AppColors.darkTextSecondary : Colors.black54;
    final labelColor = isDark ? AppColors.darkTextSecondary : Colors.black45;
    final cardBg = isDark ? AppColors.darkSurface : const Color(0xFFEBF3EA);
    final chipBg = isDark ? AppColors.darkSurfaceVariant : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: chipBg,
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? AppColors.darkBorder : Colors.transparent),
            ),
            child: Icon(Icons.arrow_back, color: primaryColor, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (facility.verified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFEBF3EA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppColors.darkBorder : Colors.transparent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: primaryColor, size: 14),
                        const SizedBox(width: 4),
                        Text(l10n.verifiedMidwife, style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  facility.name.toLowerCase(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                if (facility.type.trim().isNotEmpty &&
                    facility.type.trim().toLowerCase() != 'maternal health specialist' &&
                    facility.type.trim().toLowerCase() != 'maternal health') ...[
                  const SizedBox(height: 4),
                  Text(
                    facility.type.trim(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                
                Text(
                  l10n.aboutMidwife(facility.name.split(" ").first),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.dedicatedMidwifeDesc,
                  style: TextStyle(fontSize: 15, color: textSecondary, height: 1.4),
                ),
                const SizedBox(height: 32),
                
                // Hospital and Experience Cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.darkBorder : Colors.transparent),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.hospital, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelColor)),
                            const SizedBox(height: 8),
                            Text(
                              facility.address.isNotEmpty ? facility.address : 'Tikur Anbessa',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.darkBorder : Colors.transparent),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.experience, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelColor)),
                            const SizedBox(height: 8),
                            Text(
                              '0+ Years',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Languages
                Text(l10n.languages, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: labelColor)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [
                    _buildLanguageChip(context, 'English'),
                    _buildLanguageChip(context, 'አማርኛ'),
                  ],
                ),
                const SizedBox(height: 32),

                // Offered Consultations
                Text(l10n.offeredConsultations, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: labelColor)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildConsultationChip(context, Icons.home_outlined, l10n.inPerson),
                    _buildConsultationChip(context, Icons.videocam_outlined, l10n.voiceCall),
                  ],
                ),
              ],
            ),
          ),
          
          // Bottom Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF9FAEB),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 20,
                    spreadRadius: 10,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.chat_bubble_outline, color: primaryColor, size: 18),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          l10n.message,
                          style: TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MidwifeBookingScreen(facility: facility),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 18),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          l10n.book,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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

  Widget _buildLanguageChip(BuildContext context, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF385A2E);
    final chipBg = isDark ? AppColors.darkSurfaceVariant : Colors.white;
    final chipBorder = isDark ? AppColors.darkBorder : Colors.black12;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipBorder),
      ),
      child: Text(
        lang,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor),
      ),
    );
  }

  Widget _buildConsultationChip(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : Colors.black87;
    final chipBg = isDark ? AppColors.darkSurfaceVariant : Colors.white;
    final chipBorder = isDark ? AppColors.darkBorder : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor),
          ),
        ],
      ),
    );
  }
}
