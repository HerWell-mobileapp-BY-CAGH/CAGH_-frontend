import 'package:flutter/material.dart';
import '../../domain/entities/healthcare_facility.dart';
import 'facility_card.dart';

class FacilityBottomSheet extends StatelessWidget {
  final List<HealthcareFacility> facilities;
  final double radius;

  const FacilityBottomSheet({
    super.key,
    required this.facilities,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F4),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nearby Facilities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF315E26),
                      ),
                    ),
                    Text(
                      '${facilities.length} within ${radius.toInt()} km',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List of Facilities
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: facilities.length,
                  padding: const EdgeInsets.only(bottom: 24, top: 8),
                  itemBuilder: (context, index) {
                    return FacilityCard(facility: facilities[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
