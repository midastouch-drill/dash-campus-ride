
class ApiException implements Exception {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final int? statusCode;
  final dynamic responseData;
  
  ApiException(
    this.message, {
    this.error,
    this.stackTrace,
    this.statusCode,
    this.responseData,
  });
  
  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: $message (Status Code: $statusCode)';
    }
    return 'ApiException: $message';
  }
  
  // Helper method to determine if this is an authentication error
  bool get isAuthError => statusCode == 401;
  
  // Helper method to determine if this is a validation error
  bool get isValidationError => statusCode == 422;
  
  // Helper method to determine if this is a server error
  bool get isServerError => statusCode != null && statusCode! >= 500;
  
  // Helper method to determine if this is a network error
  bool get isNetworkError => message.contains('No internet connection') || 
                            message.contains('Connection timeout');
  
  // Extract specific field errors from validation errors
  Map<String, String> getFieldErrors() {
    final Map<String, String> fieldErrors = {};
    
    if (isValidationError && responseData != null) {
      try {
        final errors = responseData['errors'];
        if (errors is Map<String, dynamic>) {
          errors.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              fieldErrors[key] = value.first.toString();
            } else if (value is String) {
              fieldErrors[key] = value;
            }
          });
        }
      } catch (e) {
        // Fallback if errors aren't in the expected format
      }
    }
    
    return fieldErrors;
  }
  
  // Get user-friendly error message
  String getUserFriendlyMessage() {
    if (isNetworkError) {
      return 'Unable to connect to the server. Please check your internet connection and try again.';
    } else if (isAuthError) {
      return 'Your session has expired. Please log in again.';
    } else if (isServerError) {
      return 'Our servers are experiencing issues. Please try again later.';
    } else {
      return message;
    }
  }
}
