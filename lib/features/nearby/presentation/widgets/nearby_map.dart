import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/healthcare_facility.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

class NearbyMap extends StatefulWidget {
  final Position userLocation;
  final List<HealthcareFacility> facilities;
  final Function(HealthcareFacility) onFacilitySelected;
  final VoidCallback onMyLocationTapped;

  const NearbyMap({
    super.key,
    required this.userLocation,
    required this.facilities,
    required this.onFacilitySelected,
    required this.onMyLocationTapped,
  });

  @override
  State<NearbyMap> createState() => _NearbyMapState();
}

class _NearbyMapState extends State<NearbyMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  @override
  void didUpdateWidget(covariant NearbyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.facilities != widget.facilities) {
      _buildMarkers();
    }
    // We do NOT aggressively move the camera here when location changes,
    // to allow the user to pan around without being snapped back.
  }

  void _buildMarkers() {
    final markers = <Marker>{};

    for (var facility in widget.facilities) {
      // Choose hue based on type (simple approximation since custom icons require async loading)
      double hue;
      if (facility.type == 'Emergency') {
        hue = BitmapDescriptor.hueRed;
      } else if (facility.type == 'Hospital') {
        hue = BitmapDescriptor.hueAzure;
      } else if (facility.type == 'Midwife') {
        hue = BitmapDescriptor.hueRose;
      } else {
        hue = BitmapDescriptor.hueGreen;
      }

      markers.add(
        Marker(
          markerId: MarkerId(facility.id),
          position: LatLng(facility.latitude, facility.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: facility.name,
            snippet: facility.type,
            onTap: () => widget.onFacilitySelected(facility),
          ),
          onTap: () {
            // Optional: Handle map marker tap specifically here
          },
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.userLocation.latitude, widget.userLocation.longitude),
            zoom: 14.0,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false, // Custom button below
          zoomControlsEnabled: false,
          mapType: MapType.normal,
        ),
        
        // Custom My Location Button
        Positioned(
          right: 16,
          bottom: 120, // Above the bottom sheet
          child: FloatingActionButton(
            heroTag: 'my_location_btn',
            backgroundColor: Colors.white,
            mini: true,
            onPressed: () {
              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(widget.userLocation.latitude, widget.userLocation.longitude),
                    15.0,
                  ),
                );
              }
              widget.onMyLocationTapped();
            },
            child: const Icon(Icons.my_location, color: AppColors.primaryGreen),
          ),
        ),
      ],
    );
  }
}
