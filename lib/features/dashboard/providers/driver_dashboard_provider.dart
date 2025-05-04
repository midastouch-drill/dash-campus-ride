
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_dash/core/services/api_service.dart';
import 'package:campus_dash/features/dashboard/models/driver_earnings_model.dart';

class DriverDashboardState {
  final bool isLoading;
  final String? error;
  final DriverEarnings? dailyEarnings;
  final DriverEarnings? weeklyEarnings;
  final DriverEarnings? monthlyEarnings;
  
  DriverDashboardState({
    this.isLoading = false,
    this.error,
    this.dailyEarnings,
    this.weeklyEarnings,
    this.monthlyEarnings,
  });
  
  DriverDashboardState copyWith({
    bool? isLoading,
    String? error,
    DriverEarnings? dailyEarnings,
    DriverEarnings? weeklyEarnings,
    DriverEarnings? monthlyEarnings,
  }) {
    return DriverDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      dailyEarnings: dailyEarnings ?? this.dailyEarnings,
      weeklyEarnings: weeklyEarnings ?? this.weeklyEarnings,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
    );
  }
}

class DriverDashboardNotifier extends StateNotifier<DriverDashboardState> {
  final ApiService _apiService;
  
  DriverDashboardNotifier(this._apiService) : super(DriverDashboardState());
  
  Future<void> fetchDailyEarnings() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.get('/drivers/earnings', queryParameters: {
        'period': 'daily',
      });
      
      final earningsData = response['data'];
      final earnings = DriverEarnings.fromJson({
        ...earningsData,
        'period': 'daily',
      });
      
      state = state.copyWith(
        isLoading: false,
        dailyEarnings: earnings,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> fetchWeeklyEarnings() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.get('/drivers/earnings', queryParameters: {
        'period': 'weekly',
      });
      
      final earningsData = response['data'];
      final earnings = DriverEarnings.fromJson({
        ...earningsData,
        'period': 'weekly',
      });
      
      state = state.copyWith(
        isLoading: false,
        weeklyEarnings: earnings,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> fetchMonthlyEarnings() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.get('/drivers/earnings', queryParameters: {
        'period': 'monthly',
      });
      
      final earningsData = response['data'];
      final earnings = DriverEarnings.fromJson({
        ...earningsData,
        'period': 'monthly',
      });
      
      state = state.copyWith(
        isLoading: false,
        monthlyEarnings: earnings,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> fetchAllEarnings() async {
    await Future.wait([
      fetchDailyEarnings(),
      fetchWeeklyEarnings(),
      fetchMonthlyEarnings(),
    ]);
  }
}

final driverDashboardProvider = StateNotifierProvider<DriverDashboardNotifier, DriverDashboardState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return DriverDashboardNotifier(apiService);
});
