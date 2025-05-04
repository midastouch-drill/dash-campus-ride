
class ApiException implements Exception {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  
  ApiException(this.message, {this.error, this.stackTrace});
  
  @override
  String toString() {
    return 'ApiException: $message';
  }
}
