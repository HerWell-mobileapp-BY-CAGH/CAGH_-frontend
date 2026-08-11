import 'package:flutter/material.dart';

class NearbyEmptyState extends StatelessWidget {
  final VoidCallback onExpandRadius;
  final VoidCallback onClearFilters;

  const NearbyEmptyState({
    super.key,
    required this.onExpandRadius,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Color(0xFF315E26),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No healthcare facilities found nearby.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Try increasing your search radius or changing your filters.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onExpandRadius,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF315E26),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Expand Search Radius'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onClearFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF315E26), side: const BorderSide(color: Color(0xFF315E26)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Clear Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
