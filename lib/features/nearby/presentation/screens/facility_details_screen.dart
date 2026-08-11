import 'package:flutter/material.dart';
import '../../domain/entities/healthcare_facility.dart';

class FacilityDetailsScreen extends StatelessWidget {
  final HealthcareFacility facility;

  const FacilityDetailsScreen({super.key, required this.facility});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        title: const Text('Facility Details', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image Placeholder
            Container(
              width: double.infinity,
              height: 180,
              color: const Color(0xFF315E26).withOpacity(0.1),
              child: const Icon(
                Icons.local_hospital_outlined,
                size: 80,
                color: Color(0xFF315E26),
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
                            color: Color(0xFF1B5E20),
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
                          child: const Row(
                            children: [
                              Icon(Icons.verified, color: Colors.blue, size: 14),
                              SizedBox(width: 4),
                              Text('Verified', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
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
                    facility.isOpen ? 'Currently Open' : 'Closed', 
                    facility.openingHours.join(', '),
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
                      child: const Row(
                        children: [
                          Icon(Icons.emergency, color: Colors.red),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '24/7 Emergency Services Available',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Text('Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: facility.services.map((service) {
                      return Chip(
                        label: Text(service, style: const TextStyle(color: Color(0xFF1B5E20))),
                        backgroundColor: const Color(0xFFE8F5E9),
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
                      onPressed: () {},
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text('Get Directions', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
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
                        onPressed: () {},
                        icon: const Icon(Icons.call, color: Color(0xFF1B5E20)),
                        label: const Text('Call Facility', style: TextStyle(color: Color(0xFF1B5E20), fontSize: 16, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1B5E20)),
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

  Widget _buildInfoRow(IconData icon, String title, String subtitle, {Color iconColor = const Color(0xFF315E26)}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
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
