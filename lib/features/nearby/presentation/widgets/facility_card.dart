import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/healthcare_facility.dart';
import '../screens/facility_details_screen.dart';

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
                      color: facility.emergencyAvailable ? Colors.red.shade50 : const Color(0xFFE8F5E9),
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
                                color: facility.emergencyAvailable ? Colors.red : const Color(0xFF315E26),
                                size: 28,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              _getIconForType(),
                              color: facility.emergencyAvailable ? Colors.red : const Color(0xFF315E26),
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
                          color: Color(0xFF315E26),
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
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      service,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  );
                }).toList(),
              ),
              if (facility.services.length > 3) ...[
                const SizedBox(height: 8),
                Text(
                  '+ ${facility.services.length - 3} more services',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
                        foregroundColor: const Color(0xFF315E26), side: const BorderSide(color: Color(0xFF315E26)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final fallbackUrl = 'https://www.google.com/maps/search/?api=1&query=${facility.latitude},${facility.longitude}';
                        final navUrls = facility.navigationUrls;
                        
                        String urlToLaunch = fallbackUrl;
                        if (navUrls != null && navUrls['google_maps'] != null) {
                          urlToLaunch = navUrls['google_maps'];
                        }
                        
                        final uri = Uri.parse(urlToLaunch);
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF315E26),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Directions'),
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
