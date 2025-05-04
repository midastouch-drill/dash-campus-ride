
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_dash/core/services/api_service.dart';
import 'package:campus_dash/core/services/storage_service.dart';
import 'package:campus_dash/features/auth/models/user_model.dart';

enum AuthStatus {
  initializing,
  authenticated,
  unauthenticated,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final bool isInitializing;
  final bool isOnboardingComplete;
  
  AuthState({
    required this.status,
    this.user,
    required this.isInitializing,
    required this.isOnboardingComplete,
  });
  
  bool get isLoggedIn => status == AuthStatus.authenticated && user != null;
  
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? isInitializing,
    bool? isOnboardingComplete,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isInitializing: isInitializing ?? this.isInitializing,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final StorageService _storageService;
  
  AuthNotifier(this._apiService, this._storageService)
      : super(AuthState(
          status: AuthStatus.initializing,
          isInitializing: true,
          isOnboardingComplete: false,
        )) {
    _initializeAuth();
  }
  
  Future<void> _initializeAuth() async {
    try {
      // Check if onboarding is complete
      final onboardingComplete = await _storageService.isOnboardingComplete();
      
      // Check if user is logged in
      final token = await _storageService.getAuthToken();
      final userProfileJson = await _storageService.getUserProfile();
      
      if (token != null && userProfileJson != null) {
        final userMap = jsonDecode(userProfileJson) as Map<String, dynamic>;
        final user = User.fromJson(userMap);
        
        // Update state with authenticated user
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          isInitializing: false,
          isOnboardingComplete: onboardingComplete,
        );
        
        // Refresh user profile in the background
        getUserProfile();
      } else {
        // User is not logged in
        state = AuthState(
          status: AuthStatus.unauthenticated,
          isInitializing: false,
          isOnboardingComplete: onboardingComplete,
        );
      }
    } catch (e) {
      // If there's an error, consider the user as unauthenticated
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isInitializing: false,
        isOnboardingComplete: false,
      );
      if (kDebugMode) {
        print('Error initializing auth: $e');
      }
    }
  }
  
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final data = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'password': password,
      };
      
      final response = await _apiService.post('/auth/register/rider', data: data);
      
      // Extract token and user data
      final token = response['token'];
      final userData = response['data']['user'];
      final walletData = response['data']['wallet'];
      
      // Create user object
      final user = User.fromJson({
        ...userData,
        'wallet': walletData,
      });
      
      // Save data to secure storage
      await _storageService.saveAuthToken(token);
      await _storageService.saveUserId(user.id);
      await _storageService.saveUserRole(user.role);
      await _storageService.saveUserProfile(jsonEncode(user.toJson()));
      
      // Update state
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = {
        'email': email,
        'password': password,
      };
      
      final response = await _apiService.post('/auth/login', data: data);
      
      // Extract token and user data
      final token = response['token'];
      final userData = response['data']['user'];
      final walletData = response['data']['wallet'];
      
      // Create user object
      final user = User.fromJson({
        ...userData,
        'wallet': walletData,
      });
      
      // Save data to secure storage
      await _storageService.saveAuthToken(token);
      await _storageService.saveUserId(user.id);
      await _storageService.saveUserRole(user.role);
      await _storageService.saveUserProfile(jsonEncode(user.toJson()));
      
      // Update state
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> logout() async {
    try {
      // Clear secure storage
      await _storageService.clearAll();
      
      // Update state
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isInitializing: false,
        isOnboardingComplete: true, // Keep onboarding complete to avoid showing onboarding again
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error logging out: $e');
      }
      rethrow;
    }
  }
  
  Future<void> getUserProfile() async {
    try {
      final response = await _apiService.get('/users/profile');
      
      // Extract user data
      final userData = response['data']['user'];
      final walletData = response['data']['wallet'];
      
      // Create user object
      final user = User.fromJson({
        ...userData,
        'wallet': walletData,
      });
      
      // Save updated profile
      await _storageService.saveUserProfile(jsonEncode(user.toJson()));
      
      // Update state
      state = state.copyWith(user: user);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user profile: $e');
      }
      // If there's an error fetching the profile, don't change the state
    }
  }
  
  Future<void> completeOnboarding() async {
    await _storageService.setOnboardingComplete();
    state = state.copyWith(isOnboardingComplete: true);
  }
  
  Future<void> setUserRole(String role) async {
    await _storageService.saveUserRole(role);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final storageService = ref.read(storageServiceProvider);
  return AuthNotifier(apiService, storageService);
});
