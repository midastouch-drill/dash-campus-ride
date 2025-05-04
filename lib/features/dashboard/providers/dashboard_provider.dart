
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_dash/core/services/api_service.dart';
import 'package:campus_dash/features/auth/providers/auth_provider.dart';

class DashboardState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> dashboardData;

  DashboardState({
    this.isLoading = false,
    this.error,
    this.dashboardData = const {},
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? dashboardData,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      dashboardData: dashboardData ?? this.dashboardData,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final ApiService _apiService;
  final AuthNotifier _authNotifier;

  DashboardNotifier(this._apiService, this._authNotifier) : super(DashboardState());

  Future<void> fetchDashboard() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Fetch profile to get updated wallet balance
      await _authNotifier.getUserProfile();
      
      // No specific dashboard endpoint in the API, but we could fetch additional data here
      // For now, just set loading to false
      state = state.copyWith(
        isLoading: false,
        dashboardData: {},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard data: ${e.toString()}',
      );
    }
  }

  Future<void> refreshDashboard() async {
    state = state.copyWith(error: null);
    await fetchDashboard();
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return DashboardNotifier(apiService, authNotifier);
});
