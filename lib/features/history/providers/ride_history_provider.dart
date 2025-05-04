
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_dash/core/services/api_service.dart';
import 'package:campus_dash/features/history/models/ride_model.dart';

class RideHistoryState {
  final bool isLoading;
  final String? error;
  final List<Ride> rides;
  final bool hasMore;
  final int currentPage;

  RideHistoryState({
    this.isLoading = false,
    this.error,
    this.rides = const [],
    this.hasMore = true,
    this.currentPage = 1,
  });

  RideHistoryState copyWith({
    bool? isLoading,
    String? error,
    List<Ride>? rides,
    bool? hasMore,
    int? currentPage,
  }) {
    return RideHistoryState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      rides: rides ?? this.rides,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class RideHistoryNotifier extends StateNotifier<RideHistoryState> {
  final ApiService _apiService;

  RideHistoryNotifier(this._apiService) : super(RideHistoryState());

  Future<void> fetchRecentRides({
    int limit = 3,
    String status = 'all',
  }) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final queryParams = {
        'limit': limit.toString(),
        'page': '1',
      };

      if (status != 'all') {
        queryParams['status'] = status;
      }

      final response = await _apiService.get(
        '/rides/history',
        queryParameters: queryParams,
      );

      final List<Ride> rides = (response['data']['rides'] as List)
          .map((ride) => Ride.fromJson(ride))
          .toList();

      state = state.copyWith(
        isLoading: false,
        rides: rides,
        hasMore: rides.length >= limit,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load ride history: ${e.toString()}',
      );
    }
  }

  Future<void> fetchRideHistory({
    int limit = 10,
    int? page,
    String status = 'all',
  }) async {
    if (state.isLoading) return;

    final currentPage = page ?? state.currentPage;

    if (currentPage > 1 && !state.hasMore) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final queryParams = {
        'limit': limit.toString(),
        'page': currentPage.toString(),
      };

      if (status != 'all') {
        queryParams['status'] = status;
      }

      final response = await _apiService.get(
        '/rides/history',
        queryParameters: queryParams,
      );

      final List<Ride> newRides = (response['data']['rides'] as List)
          .map((ride) => Ride.fromJson(ride))
          .toList();

      final List<Ride> updatedRides = currentPage == 1
          ? newRides
          : [...state.rides, ...newRides];

      state = state.copyWith(
        isLoading: false,
        rides: updatedRides,
        hasMore: newRides.length >= limit,
        currentPage: currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load ride history: ${e.toString()}',
      );
    }
  }

  Future<void> refreshRideHistory() async {
    state = state.copyWith(
      currentPage: 1,
      hasMore: true,
      error: null,
    );
    
    await fetchRideHistory(page: 1);
  }
}

final rideHistoryProvider =
    StateNotifierProvider<RideHistoryNotifier, RideHistoryState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return RideHistoryNotifier(apiService);
});
