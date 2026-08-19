import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/healthcare_facility.dart';
import '../../domain/repositories/nearby_repository.dart';
import '../../data/repositories/nearby_repository_impl.dart';

// Providers
final nearbyRepositoryProvider = Provider<NearbyRepository>((ref) {
  return NearbyRepositoryImpl();
});

final nearbyStateProvider = StateNotifierProvider<NearbyStateNotifier, NearbyState>((ref) {
  final repository = ref.read(nearbyRepositoryProvider);
  return NearbyStateNotifier(repository);
});

// State classes
abstract class NearbyState {}

class NearbyInitial extends NearbyState {}
class NearbyLoading extends NearbyState {}
class NearbyLoaded extends NearbyState {
  final List<HealthcareFacility> facilities;
  final Position userLocation;
  final String selectedType;
  final String selectedService;
  final double radius;

  NearbyLoaded({
    required this.facilities,
    required this.userLocation,
    required this.selectedType,
    required this.selectedService,
    required this.radius,
  });
}
class NearbyLocationPermissionDenied extends NearbyState {
  final bool isPermanent;
  NearbyLocationPermissionDenied({this.isPermanent = false});
}
class NearbyLocationDisabled extends NearbyState {}
class NearbyEmpty extends NearbyState {
  final Position userLocation;
  final String selectedType;
  final String selectedService;
  final double radius;

  NearbyEmpty({
    required this.userLocation,
    required this.selectedType,
    required this.selectedService,
    required this.radius,
  });
}
class NearbyError extends NearbyState {
  final String message;
  NearbyError(this.message);
}

// State Notifier
class NearbyStateNotifier extends StateNotifier<NearbyState> {
  final NearbyRepository _repository;
  
  Position? _lastKnownPosition;
  String _currentType = 'All';
  String _currentService = 'All';
  double _currentRadius = 10.0; // 10 km default

  NearbyStateNotifier(this._repository) : super(NearbyInitial());

  Future<void> fetchNearbyFacilities({
    String? type,
    String? service,
    double? radius,
    bool forceRefreshLocation = false,
  }) async {
    state = NearbyLoading();

    try {
      if (type != null) _currentType = type;
      if (service != null) _currentService = service;
      if (radius != null) _currentRadius = radius;

      // Handle location permissions and GPS
      if (_lastKnownPosition == null || forceRefreshLocation) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          state = NearbyLocationDisabled();
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            state = NearbyLocationPermissionDenied();
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          state = NearbyLocationPermissionDenied(isPermanent: true);
          return;
        }

        _lastKnownPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }

      if (_lastKnownPosition == null) {
        state = NearbyError('Could not determine current location.');
        return;
      }

      final facilities = await _repository.getNearbyFacilities(
        latitude: _lastKnownPosition!.latitude,
        longitude: _lastKnownPosition!.longitude,
        radius: _currentRadius,
        type: _currentType,
        service: _currentService,
      );

      if (facilities.isEmpty) {
        state = NearbyEmpty(
          userLocation: _lastKnownPosition!,
          selectedType: _currentType,
          selectedService: _currentService,
          radius: _currentRadius,
        );
      } else {
        state = NearbyLoaded(
          facilities: facilities,
          userLocation: _lastKnownPosition!,
          selectedType: _currentType,
          selectedService: _currentService,
          radius: _currentRadius,
        );
      }
    } catch (e) {
      state = NearbyError('Failed to load nearby facilities: ${e.toString()}');
    }
  }

  void updateFilters({String? type, String? service, double? radius}) {
    fetchNearbyFacilities(type: type, service: service, radius: radius);
  }
}
