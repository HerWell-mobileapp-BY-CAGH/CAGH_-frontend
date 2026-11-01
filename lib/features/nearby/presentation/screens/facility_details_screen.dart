import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/healthcare_facility.dart';
import 'package:cagh_frontend/shared/constants/app_constants.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class FacilityDetailsScreen extends StatelessWidget {
  final HealthcareFacility facility;

  const FacilityDetailsScreen({super.key, required this.facility});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.facilityDetails,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image
            Container(
              width: double.infinity,
              height: 180,
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              child: facility.image != null
                  ? Image.network(
                      facility.image!,
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.local_hospital_outlined,
                        size: 80,
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : const Icon(
                      Icons.local_hospital_outlined,
                      size: 80,
                      color: AppColors.primaryGreen,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          facility.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      if (facility.verified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified, color: Colors.blue, size: 14),
                              SizedBox(width: 4),
                              Text(AppLocalizations.of(context)!.verified, style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      if (facility.rating != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              const Text('⭐️', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(facility.rating!.toStringAsFixed(1), style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    facility.type,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // Info Cards
                  _buildInfoRow(Icons.location_on, facility.address, '${facility.distance.toStringAsFixed(1)} km away'),
                  const SizedBox(height: 12),
                  if (facility.phone != null) ...[
                    _buildInfoRow(Icons.phone, facility.phone!, 'Tap to call'),
                    const SizedBox(height: 12),
                  ],
                  _buildInfoRow(
                    Icons.access_time, 
                    facility.isOpen
                        ? (Localizations.localeOf(context).languageCode == 'am' ? 'ክፍት ነው' : 'Currently Open')
                        : (Localizations.localeOf(context).languageCode == 'am' ? 'ዝግ ነው' : 'Closed'), 
                    facility.operatingHours ?? 'Not specified',
                    iconColor: facility.isOpen ? Colors.green : Colors.red,
                  ),
                  
                  if (facility.emergencyAvailable) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.emergency, color: Colors.red),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.emergencyServicesAvailable,
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 24),
                  Text(AppLocalizations.of(context)!.services, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: facility.services.map((service) {
                      return Chip(
                        label: Text(service, style: const TextStyle(color: AppColors.primaryGreen)),
                        backgroundColor: AppColors.lightGreen,
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 40),
                  
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final fallbackUrl = AppConstants.googleMapsSearchUrl(facility.latitude, facility.longitude);
                        final navUrls = facility.navigationUrls;
                        
                        String urlToLaunch = fallbackUrl;
                        if (navUrls != null && navUrls['google_maps'] != null) {
                          urlToLaunch = navUrls['google_maps'];
                        }
                        
                        final uri = Uri.parse(urlToLaunch);
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: Icon(Icons.directions, color: Colors.white),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppLocalizations.of(context)!.getDirections,
                          maxLines: 1,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (facility.phone != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          String phoneUrl = facility.callUrl ?? 'tel:${facility.phone}';
                          final uri = Uri.parse(phoneUrl);
                          launchUrl(uri);
                        },
                        icon: Icon(Icons.call, color: AppColors.primaryGreen),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppLocalizations.of(context)!.callFacility,
                            maxLines: 1,
                            style: const TextStyle(color: AppColors.primaryGreen, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryGreen),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle, {Color iconColor = AppColors.primaryGreen}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
            ]
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
