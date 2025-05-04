
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_dash/core/services/api_service.dart';
import 'package:campus_dash/features/ride/models/active_ride_model.dart';
import 'package:campus_dash/features/ride/models/ride_request_model.dart';
import 'package:campus_dash/features/history/models/ride_model.dart';
import 'package:campus_dash/features/auth/providers/driver_provider.dart';

class DriverRideState {
  final bool isLoadingHistory;
  final bool isLoadingRequests;
  final bool isLoadingActiveRide;
  final String? error;
  final List<RideRequest> rideRequests;
  final List<Ride> completedRides;
  final ActiveRide? activeRide;
  final bool hasMoreRides;
  final int currentPage;
  final double todayEarnings;
  final int todayCompletedRides;
  
  DriverRideState({
    this.isLoadingHistory = false,
    this.isLoadingRequests = false,
    this.isLoadingActiveRide = false,
    this.error,
    this.rideRequests = const [],
    this.completedRides = const [],
    this.activeRide,
    this.hasMoreRides = true,
    this.currentPage = 1,
    this.todayEarnings = 0,
    this.todayCompletedRides = 0,
  });
  
  DriverRideState copyWith({
    bool? isLoadingHistory,
    bool? isLoadingRequests,
    bool? isLoadingActiveRide,
    String? error,
    List<RideRequest>? rideRequests,
    List<Ride>? completedRides,
    ActiveRide? activeRide,
    bool? clearActiveRide,
    bool? hasMoreRides,
    int? currentPage,
    double? todayEarnings,
    int? todayCompletedRides,
  }) {
    return DriverRideState(
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isLoadingRequests: isLoadingRequests ?? this.isLoadingRequests,
      isLoadingActiveRide: isLoadingActiveRide ?? this.isLoadingActiveRide,
      error: error ?? this.error,
      rideRequests: rideRequests ?? this.rideRequests,
      completedRides: completedRides ?? this.completedRides,
      activeRide: clearActiveRide == true ? null : (activeRide ?? this.activeRide),
      hasMoreRides: hasMoreRides ?? this.hasMoreRides,
      currentPage: currentPage ?? this.currentPage,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayCompletedRides: todayCompletedRides ?? this.todayCompletedRides,
    );
  }
}

class DriverRideNotifier extends StateNotifier<DriverRideState> {
  final ApiService _apiService;
  final DriverNotifier _driverNotifier;
  Timer? _rideRequestsTimer;
  
  DriverRideNotifier(this._apiService, this._driverNotifier) : super(DriverRideState()) {
    // Start polling for ride requests if driver is available
    if (_driverNotifier.state.isAvailable) {
      _startPollingForRideRequests();
    }
  }
  
  void _startPollingForRideRequests() {
    // Cancel any existing timer
    _rideRequestsTimer?.cancel();
    
    // Poll every 5 seconds
    _rideRequestsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_driverNotifier.state.isAvailable && state.activeRide == null) {
        fetchRideRequests();
      }
    });
  }
  
  void _stopPollingForRideRequests() {
    _rideRequestsTimer?.cancel();
    _rideRequestsTimer = null;
  }
  
  @override
  void dispose() {
    _stopPollingForRideRequests();
    super.dispose();
  }
  
  Future<void> fetchDriverRides({bool refresh = true}) async {
    if (state.isLoadingHistory) return;
    
    final currentPage = refresh ? 1 : state.currentPage;
    
    if (currentPage > 1 && !state.hasMoreRides) return;
    
    state = state.copyWith(isLoadingHistory: true, error: null);
    
    try {
      // Fetch active ride (if any)
      await fetchActiveRide();
      
      // Fetch completed rides
      final queryParams = {
        'limit': '10',
        'page': currentPage.toString(),
        'status': 'completed',
      };
      
      final response = await _apiService.get(
        '/drivers/rides',
        queryParameters: queryParams,
      );
      
      final List<Ride> newRides = (response['data']['rides'] as List)
          .map((ride) => Ride.fromJson(ride))
          .toList();
      
      // Calculate today's earnings
      await fetchTodayEarnings();
      
      final List<Ride> updatedRides = refresh
          ? newRides
          : [...state.completedRides, ...newRides];
      
      state = state.copyWith(
        isLoadingHistory: false,
        completedRides: updatedRides,
        hasMoreRides: newRides.length >= 10,
        currentPage: currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        error: 'Failed to load rides: ${e.toString()}',
      );
    }
  }
  
  Future<void> fetchRideRequests() async {
    // Only fetch if driver is available and has no active ride
    if (!_driverNotifier.state.isAvailable || state.activeRide != null) return;
    
    state = state.copyWith(isLoadingRequests: true, error: null);
    
    try {
      final response = await _apiService.get('/drivers/ride-requests');
      
      final List<RideRequest> requests = (response['data']['rideRequests'] as List)
          .map((request) => RideRequest.fromJson(request))
          .toList();
      
      state = state.copyWith(
        isLoadingRequests: false,
        rideRequests: requests,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingRequests: false,
        error: 'Failed to load ride requests: ${e.toString()}',
      );
    }
  }
  
  Future<void> fetchActiveRide() async {
    state = state.copyWith(isLoadingActiveRide: true, error: null);
    
    try {
      final response = await _apiService.get('/drivers/active-ride');
      
      if (response['data'] != null && response['data']['ride'] != null) {
        final activeRide = ActiveRide.fromJson(response['data']['ride']);
        
        state = state.copyWith(
          isLoadingActiveRide: false,
          activeRide: activeRide,
        );
      } else {
        state = state.copyWith(
          isLoadingActiveRide: false,
          clearActiveRide: true,
        );
      }
    } catch (e) {
      // It's expected that this might fail if there's no active ride
      state = state.copyWith(
        isLoadingActiveRide: false,
      );
    }
  }
  
  Future<void> fetchTodayEarnings() async {
    try {
      final response = await _apiService.get('/drivers/earnings', queryParameters: {
        'period': 'daily',
      });
      
      final earnings = (response['data']['earnings'] as num).toDouble();
      final completedRides = response['data']['completedRides'] as int;
      
      state = state.copyWith(
        todayEarnings: earnings,
        todayCompletedRides: completedRides,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching today\'s earnings: $e');
      }
    }
  }
  
  Future<void> acceptRide(String rideId) async {
    try {
      await _apiService.post('/rides/$rideId/accept');
      
      // Fetch the active ride
      await fetchActiveRide();
      
      // Clear ride requests since we've accepted one
      state = state.copyWith(rideRequests: []);
      
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to accept ride: ${e.toString()}',
      );
    }
  }
  
  Future<void> startRide(String rideId) async {
    try {
      await _apiService.post('/rides/$rideId/start');
      
      // Update active ride
      await fetchActiveRide();
      
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to start ride: ${e.toString()}',
      );
    }
  }
  
  Future<void> completeRide(String rideId) async {
    try {
      await _apiService.post('/rides/$rideId/complete');
      
      // Clear active ride and refresh history
      state = state.copyWith(clearActiveRide: true);
      await fetchDriverRides();
      
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to complete ride: ${e.toString()}',
      );
    }
  }
  
  Future<void> cancelRide(String rideId, String reason) async {
    try {
      await _apiService.post('/rides/$rideId/cancel', data: {
        'reason': reason,
      });
      
      // Clear active ride if this was the active one
      if (state.activeRide?.id == rideId) {
        state = state.copyWith(clearActiveRide: true);
      }
      
      // Refresh ride requests
      fetchRideRequests();
      
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to cancel ride: ${e.toString()}',
      );
    }
  }
  
  void refreshAll() {
    fetchActiveRide();
    fetchRideRequests();
    fetchDriverRides();
    fetchTodayEarnings();
  }
}

final driverRideProvider = StateNotifierProvider<DriverRideNotifier, DriverRideState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final driverNotifier = ref.read(driverProvider.notifier);
  return DriverRideNotifier(apiService, driverNotifier);
});
