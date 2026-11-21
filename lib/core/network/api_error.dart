import 'package:dio/dio.dart';

/// Contract error body: {"error":{"code":"...","message":"..."}}
class ApiException implements Exception {
  ApiException(this.code, this.message, {this.status});
  final String code;
  final String message;
  final int? status;

  bool get isInactive => code == 'inactive';

  factory ApiException.from(Object e) {
    if (e is ApiException) return e;
    if (e is DioException) {
      final res = e.response;
      final data = res?.data;
      if (data is Map && data['error'] is Map) {
        final err = data['error'] as Map;
        return ApiException(
          (err['code'] ?? 'internal').toString(),
          (err['message'] ?? 'Something went wrong.').toString(),
          status: res?.statusCode,
        );
      }
      switch (e.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiException('network', 'No connection. Check your internet and try again.');
        default:
          return ApiException('internal', 'Server error (${res?.statusCode ?? 'no response'}).',
              status: res?.statusCode);
      }
    }
    return ApiException('internal', 'Something went wrong.');
  }

  @override
  String toString() => message;
}
