
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_dash/core/services/api_service.dart';
import 'package:campus_dash/features/ride/models/active_ride_model.dart';

class ActiveRideState {
  final bool isLoading;
  final String? error;
  final ActiveRide? ride;

  ActiveRideState({
    this.isLoading = false,
    this.error,
    this.ride,
  });

  ActiveRideState copyWith({
    bool? isLoading,
    String? error,
    ActiveRide? ride,
  }) {
    return ActiveRideState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      ride: ride ?? this.ride,
    );
  }
}

class ActiveRideNotifier extends StateNotifier<ActiveRideState> {
  final ApiService _apiService;

  ActiveRideNotifier(this._apiService) : super(ActiveRideState());

  Future<void> fetchRideDetails(String rideId) async {
    // Don't set loading to true if we're polling for updates and already have ride data
    final isInitialLoad = state.ride == null;
    
    if (isInitialLoad) {
      state = state.copyWith(isLoading: true, error: null);
    }
    
    try {
      final response = await _apiService.get('/rides/$rideId');
      final rideData = response['data']['ride'];
      
      state = state.copyWith(
        isLoading: false,
        ride: ActiveRide.fromJson(rideData),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load ride details: ${e.toString()}',
      );
    }
  }

  Future<void> cancelRide(String rideId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final data = {
        'reason': 'Cancelled by user',
      };
      
      await _apiService.post('/rides/$rideId/cancel', data: data);
      
      // Update the local state with cancelled status
      if (state.ride != null) {
        state = state.copyWith(
          isLoading: false,
          ride: state.ride!.copyWith(status: RideStatus.cancelled),
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel ride: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> rateRide(String rideId, double rating, String? review) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final data = {
        'rating': rating,
        'review': review,
      };
      
      await _apiService.post('/rides/$rideId/rate', data: data);
      
      // Update the local state with rating
      if (state.ride != null) {
        state = state.copyWith(
          isLoading: false,
          ride: state.ride!.copyWith(
            rating: rating,
            review: review,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to rate ride: ${e.toString()}',
      );
      rethrow;
    }
  }
}

final activeRideProvider =
    StateNotifierProvider<ActiveRideNotifier, ActiveRideState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return ActiveRideNotifier(apiService);
});
