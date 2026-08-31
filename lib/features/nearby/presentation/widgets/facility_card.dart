import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/healthcare_facility.dart';
import 'package:cagh_frontend/shared/constants/app_constants.dart';
import '../screens/facility_details_screen.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class FacilityCard extends StatelessWidget {
  final HealthcareFacility facility;

  const FacilityCard({super.key, required this.facility});

  IconData _getIconForType() {
    switch (facility.type) {
      case 'Hospital':
        return Icons.local_hospital;
      case 'Health Center':
        return Icons.business;
      case 'Clinic':
        return Icons.medical_services;
      case 'Midwife':
        return Icons.pregnant_woman;
      case 'Pharmacy':
        return Icons.local_pharmacy;
      case 'Emergency':
        return Icons.emergency;
      default:
        return Icons.local_hospital;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FacilityDetailsScreen(facility: facility),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: facility.emergencyAvailable ? Colors.red.shade50 : AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: facility.image != null
                        ? Image.network(
                            facility.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                _getIconForType(),
                                color: facility.emergencyAvailable ? Colors.red : AppColors.primaryGreen,
                                size: 28,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              _getIconForType(),
                              color: facility.emergencyAvailable ? Colors.red : AppColors.primaryGreen,
                              size: 28,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                facility.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (facility.verified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Colors.blue, size: 16),
                            ]
                          ],
                        ),
                        if (facility.rating != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text('⭐️', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                facility.rating!.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          facility.type,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${facility.distance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: facility.isOpen ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            facility.isOpen ? 'Open' : 'Closed',
                            style: TextStyle(
                              fontSize: 12,
                              color: facility.isOpen ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: facility.services.take(3).map((service) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    child: Text(
                      service,
                      style: TextStyle(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade700),
                    ),
                  );
                }).toList(),
              ),
              if (facility.services.length > 3) ...[
                const SizedBox(height: 8),
                Text(
                  '+ ${facility.services.length - 3} more services',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade500),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FacilityDetailsScreen(facility: facility),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen, side: const BorderSide(color: AppColors.primaryGreen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(AppLocalizations.of(context)!.directions),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
