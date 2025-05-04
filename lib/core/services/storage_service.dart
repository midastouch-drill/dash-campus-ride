
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage;
  
  StorageService(this._secureStorage);
  
  // Keys
  static const String tokenKey = 'auth_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String userProfileKey = 'user_profile';
  static const String onboardingCompleteKey = 'onboarding_complete';
  
  // Authentication
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: tokenKey, value: token);
  }
  
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: tokenKey);
  }
  
  Future<void> deleteAuthToken() async {
    await _secureStorage.delete(key: tokenKey);
  }
  
  // User Role
  Future<void> saveUserRole(String role) async {
    await _secureStorage.write(key: userRoleKey, value: role);
  }
  
  Future<String?> getUserRole() async {
    return await _secureStorage.read(key: userRoleKey);
  }
  
  // User ID
  Future<void> saveUserId(String userId) async {
    await _secureStorage.write(key: userIdKey, value: userId);
  }
  
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: userIdKey);
  }
  
  // User Profile
  Future<void> saveUserProfile(String profileJson) async {
    await _secureStorage.write(key: userProfileKey, value: profileJson);
  }
  
  Future<String?> getUserProfile() async {
    return await _secureStorage.read(key: userProfileKey);
  }
  
  // Onboarding Status
  Future<void> setOnboardingComplete() async {
    await _secureStorage.write(key: onboardingCompleteKey, value: 'true');
  }
  
  Future<bool> isOnboardingComplete() async {
    final value = await _secureStorage.read(key: onboardingCompleteKey);
    return value == 'true';
  }
  
  // Clear all data
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(const FlutterSecureStorage());
});
