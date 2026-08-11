import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionView extends StatelessWidget {
  final bool isDisabled;
  final bool isPermanentlyDenied;
  final VoidCallback onRetry;

  const LocationPermissionView({
    super.key,
    this.isDisabled = false,
    this.isPermanentlyDenied = false,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDisabled ? Icons.location_off : Icons.security,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              isDisabled
                  ? 'Location services are disabled'
                  : isPermanentlyDenied
                      ? 'Location permission denied'
                      : 'Location access required',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isDisabled
                  ? 'Please turn on your GPS to find nearby healthcare facilities.'
                  : isPermanentlyDenied
                      ? 'You have permanently denied location permissions. Please enable them from your phone settings.'
                      : 'We need your location to show healthcare facilities near you.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (isDisabled) {
                  await Geolocator.openLocationSettings();
                } else if (isPermanentlyDenied) {
                  await Geolocator.openAppSettings();
                } else {
                  onRetry();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF315E26),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isDisabled || isPermanentlyDenied ? 'Open Settings' : 'Allow Access',
              ),
            ),
            if (!isDisabled && !isPermanentlyDenied) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
