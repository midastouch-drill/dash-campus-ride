
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_dash/core/services/storage_service.dart';
import 'package:campus_dash/core/utils/api_exception.dart';

class ApiService {
  final Dio _dio;
  final StorageService _storageService;
  
  ApiService(this._dio, this._storageService) {
    _configureInterceptors();
  }
  
  static const String baseUrl = 'https://dash-d77z.onrender.com/api/v1';
  
  void _configureInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token to all requests except auth related ones
          if (!options.path.contains('/auth/')) {
            final token = await _storageService.getAuthToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          
          // Add common headers
          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept'] = 'application/json';
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Token expired, logout user
            await _storageService.clearAll();
            // Navigate to login screen - this will be handled by the auth state
          }
          return handler.next(e);
        },
      ),
    );
    
    // Log requests in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ));
    }
  }
  
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(
        '$baseUrl$path',
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(
        '$baseUrl$path',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(
        '$baseUrl$path',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<dynamic> delete(String path, {dynamic data}) async {
    try {
      final response = await _dio.delete(
        '$baseUrl$path',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Exception _handleError(DioException e) {
    if (e.error is SocketException) {
      return ApiException('No internet connection');
    }
    
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data['message'] ?? 'Server error';
        
        switch (statusCode) {
          case 400:
            return ApiException('Bad request: $message');
          case 401:
            return ApiException('Unauthorized: $message');
          case 403:
            return ApiException('Forbidden: $message');
          case 404:
            return ApiException('Not found: $message');
          case 422:
            return ApiException('Validation error: $message');
          case 500:
          default:
            return ApiException('Server error: $message');
        }
      default:
        return ApiException('Something went wrong');
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = Dio();
  final storageService = ref.read(storageServiceProvider);
  return ApiService(dio, storageService);
});
