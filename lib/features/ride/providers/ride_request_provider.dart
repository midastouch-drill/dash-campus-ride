
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_dash/core/services/api_service.dart';

class RideRequestState {
  final bool isRequestingRide;
  final String? error;
  final double distance; // in km
  final int duration; // in minutes
  final double fare;
  final GeoPoint? pickupLocation;
  final String? pickupAddress;
  final GeoPoint? dropoffLocation;
  final String? dropoffAddress;
  final String? rideId;

  RideRequestState({
    this.isRequestingRide = false,
    this.error,
    this.distance = 0.0,
    this.duration = 0,
    this.fare = 0.0,
    this.pickupLocation,
    this.pickupAddress,
    this.dropoffLocation,
    this.dropoffAddress,
    this.rideId,
  });

  RideRequestState copyWith({
    bool? isRequestingRide,
    String? error,
    double? distance,
    int? duration,
    double? fare,
    GeoPoint? pickupLocation,
    String? pickupAddress,
    GeoPoint? dropoffLocation,
    String? dropoffAddress,
    String? rideId,
  }) {
    return RideRequestState(
      isRequestingRide: isRequestingRide ?? this.isRequestingRide,
      error: error ?? this.error,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      fare: fare ?? this.fare,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      rideId: rideId ?? this.rideId,
    );
  }
}

class RideRequestNotifier extends StateNotifier<RideRequestState> {
  final ApiService _apiService;

  RideRequestNotifier(this._apiService) : super(RideRequestState());

  void setRideDetails({
    required double distance,
    required int duration,
    required GeoPoint pickupLocation,
    required String pickupAddress,
    required GeoPoint dropoffLocation,
    required String dropoffAddress,
  }) {
    // Calculate fare based on distance and duration
    // Example: Base fare of ₦500 + ₦100 per km + ₦20 per minute
    final baseFare = 500.0;
    final perKmFare = 100.0;
    final perMinuteFare = 20.0;
    
    final calculatedFare = baseFare + (distance * perKmFare) + (duration * perMinuteFare);
    
    state = state.copyWith(
      distance: distance,
      duration: duration,
      fare: calculatedFare,
      pickupLocation: pickupLocation,
      pickupAddress: pickupAddress,
      dropoffLocation: dropoffLocation,
      dropoffAddress: dropoffAddress,
    );
  }

  Future<String?> requestRide() async {
    if (state.pickupLocation == null || state.dropoffLocation == null) {
      state = state.copyWith(
        error: 'Pickup and dropoff locations are required',
      );
      return null;
    }

    state = state.copyWith(
      isRequestingRide: true,
      error: null,
    );

    try {
      final data = {
        'pickupLocation': {
          'name': state.pickupAddress,
          'coordinates': [
            state.pickupLocation!.longitude,
            state.pickupLocation!.latitude,
          ],
        },
        'dropoffLocation': {
          'name': state.dropoffAddress,
          'coordinates': [
            state.dropoffLocation!.longitude,
            state.dropoffLocation!.latitude,
          ],
        },
        'distance': state.distance,
        'duration': state.duration,
        'paymentMethod': 'cash', // Default payment method
      };

      final response = await _apiService.post('/rides/request', data: data);
      
      final rideId = response['data']['ride']['id'];

      state = state.copyWith(
        isRequestingRide: false,
        rideId: rideId,
      );

      return rideId;
    } catch (e) {
      state = state.copyWith(
        isRequestingRide: false,
        error: 'Failed to request ride: ${e.toString()}',
      );
      return null;
    }
  }
}

final rideRequestProvider = StateNotifierProvider<RideRequestNotifier, RideRequestState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return RideRequestNotifier(apiService);
});
