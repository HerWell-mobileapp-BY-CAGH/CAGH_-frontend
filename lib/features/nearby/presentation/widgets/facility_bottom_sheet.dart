import 'package:flutter/material.dart';
import '../../domain/entities/healthcare_facility.dart';
import 'facility_card.dart';

class FacilityBottomSheet extends StatefulWidget {
  final List<HealthcareFacility> facilities;
  final double radius;

  const FacilityBottomSheet({
    super.key,
    required this.facilities,
    required this.radius,
  });

  @override
  State<FacilityBottomSheet> createState() => _FacilityBottomSheetState();
}

class _FacilityBottomSheetState extends State<FacilityBottomSheet> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: MediaQuery.of(context).size.height * (_isExpanded ? 0.8 : 0.4),
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
            // Drag Handle / Tap to expand
            GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < -2 && !_isExpanded) {
                  setState(() => _isExpanded = true);
                } else if (details.primaryDelta! > 2 && _isExpanded) {
                  setState(() => _isExpanded = false);
                }
              },
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
              },
              child: Container(
                width: double.infinity,
                color: Colors.transparent, // expand tap area
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
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
                    '${widget.facilities.length} within ${widget.radius.toInt()} km',
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
                itemCount: widget.facilities.length,
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                itemBuilder: (context, index) {
                  return FacilityCard(facility: widget.facilities[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
