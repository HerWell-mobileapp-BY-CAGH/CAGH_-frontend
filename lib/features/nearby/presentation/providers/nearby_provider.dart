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
  double _currentRadius = 10.0;

  NearbyStateNotifier(this._repository) : super(NearbyInitial());

  Future<void> fetchNearbyFacilities({
    String? type,
    String? service,
    double? radius,
    bool forceRefreshLocation = false,
  }) async {
    // If state is already NearbyLoaded with identical parameters, retain cached data immediately
    final targetType = type ?? _currentType;
    final targetService = service ?? _currentService;
    final targetRadius = radius ?? _currentRadius;

    if (state is NearbyLoaded &&
        !forceRefreshLocation &&
        targetType == _currentType &&
        targetService == _currentService &&
        targetRadius == _currentRadius) {
      return;
    }

    state = NearbyLoading();

    try {
      _currentType = targetType;
      _currentService = targetService;
      _currentRadius = targetRadius;

      if (_lastKnownPosition == null || forceRefreshLocation) {
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) {
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
            }
            if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
              // Fast path: try cached last known position (<5ms!)
              _lastKnownPosition = await Geolocator.getLastKnownPosition();
              _lastKnownPosition ??= await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
              ).timeout(const Duration(seconds: 2));
            }
          }
        } catch (_) {}

        _lastKnownPosition ??= Position(
          latitude: 9.0300,
          longitude: 38.7400,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 2355.0,
          altitudeAccuracy: 10.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
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
