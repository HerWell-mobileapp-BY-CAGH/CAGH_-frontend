import 'package:flutter/material.dart';
import '../../domain/entities/healthcare_facility.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'midwife_booking_screen.dart';

class MidwifeDetailScreen extends StatelessWidget {
  final HealthcareFacility facility;

  const MidwifeDetailScreen({super.key, required this.facility});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAEB), // Very light pale green/yellow background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Color(0xFF385A2E), size: 20),
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
                      color: const Color(0xFFEBF3EA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF385A2E), size: 14),
                        const SizedBox(width: 4),
                        Text(l10n.verifiedMidwife, style: const TextStyle(color: Color(0xFF385A2E), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  facility.name.toLowerCase(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF182335),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.maternalHealthSpecialist,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF385A2E),
                  ),
                ),
                const SizedBox(height: 32),
                
                Text(
                  l10n.aboutMidwife(facility.name.split(" ").first),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF182335)),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.dedicatedMidwifeDesc,
                  style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 32),
                
                // Hospital and Experience Cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF3EA), // Light green
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.hospital, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45)),
                            const SizedBox(height: 8),
                            Text(
                              facility.address.isNotEmpty ? facility.address : 'Tikur Anbessa',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF182335)),
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
                          color: const Color(0xFFEBF3EA), // Light green
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.experience, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45)),
                            const SizedBox(height: 8),
                            const Text(
                              '0+ Years',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF182335)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Languages
                Text(l10n.languages, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [
                    _buildLanguageChip('English'),
                    _buildLanguageChip('አማርኛ'),
                  ],
                ),
                const SizedBox(height: 32),

                // Offered Consultations
                Text(l10n.offeredConsultations, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildConsultationChip(Icons.home_outlined, l10n.inPerson),
                    const SizedBox(width: 12),
                    _buildConsultationChip(Icons.videocam_outlined, l10n.voiceCall),
                  ],
                ),
              ],
            ),
          ),
          
          // Bottom Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAEB),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF9FAEB).withOpacity(0.9),
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
                      icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF385A2E), size: 20),
                      label: Text(l10n.message, style: const TextStyle(color: Color(0xFF385A2E), fontSize: 16, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF385A2E)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                      icon: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 20),
                      label: Text(l10n.book, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF385A2E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildLanguageChip(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        lang,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF385A2E)),
      ),
    );
  }

  Widget _buildConsultationChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
