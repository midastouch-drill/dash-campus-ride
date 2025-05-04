
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_dash/core/services/api_service.dart';
import 'package:campus_dash/features/auth/models/driver_model.dart';
import 'package:campus_dash/features/auth/providers/auth_provider.dart';

class DriverState {
  final Driver? driver;
  final bool isLoading;
  final String? error;
  final bool isAvailable;
  
  DriverState({
    this.driver,
    this.isLoading = false,
    this.error,
    this.isAvailable = false,
  });
  
  DriverState copyWith({
    Driver? driver,
    bool? isLoading,
    String? error,
    bool? isAvailable,
  }) {
    return DriverState(
      driver: driver ?? this.driver,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class DriverNotifier extends StateNotifier<DriverState> {
  final ApiService _apiService;
  final AuthNotifier _authNotifier;
  
  DriverNotifier(this._apiService, this._authNotifier) : super(DriverState()) {
    if (_authNotifier.state.user?.role == 'driver') {
      _loadDriverProfile();
    }
  }
  
  Future<void> _loadDriverProfile() async {
    if (state.isLoading) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.get('/drivers/profile');
      
      final driverData = response['data']['driver'];
      final walletData = response['data']['wallet'];
      
      final driver = Driver.fromJson({
        ...driverData,
        'wallet': walletData,
      });
      
      state = state.copyWith(
        driver: driver,
        isLoading: false,
        isAvailable: driver.isAvailable,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> updateAvailability(bool isAvailable) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _apiService.patch('/drivers/availability', data: {
        'isAvailable': isAvailable,
      });
      
      state = state.copyWith(
        isLoading: false,
        isAvailable: isAvailable,
        driver: state.driver?.copyWith(isAvailable: isAvailable),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> updateLocation(List<double> coordinates) async {
    try {
      await _apiService.patch('/drivers/location', data: {
        'coordinates': coordinates,
      });
      
      state = state.copyWith(
        driver: state.driver?.copyWith(currentLocation: coordinates),
      );
    } catch (e) {
      // Silently fail for location updates to prevent UI disruption
      if (kDebugMode) {
        print('Error updating driver location: $e');
      }
    }
  }
  
  Future<void> updateDriverProfile({
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleColor,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final data = {
        if (vehicleMake != null) 'vehicleMake': vehicleMake,
        if (vehicleModel != null) 'vehicleModel': vehicleModel,
        if (vehicleColor != null) 'vehicleColor': vehicleColor,
      };
      
      final response = await _apiService.patch('/drivers/profile', data: data);
      
      final updatedDriverData = response['data']['driver'];
      final walletData = response['data']['wallet'];
      
      final updatedDriver = Driver.fromJson({
        ...updatedDriverData,
        'wallet': walletData,
      });
      
      state = state.copyWith(
        driver: updatedDriver,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> refreshDriverProfile() async {
    await _loadDriverProfile();
  }
}

final driverProvider = StateNotifierProvider<DriverNotifier, DriverState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return DriverNotifier(apiService, authNotifier);
});
