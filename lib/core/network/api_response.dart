// Server envelope: { success, code, message, data }
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.code,
    required this.message,
    this.data,
  });

  // Throws FormatException or TypeError when the body is not an envelope
  factory ApiResponse.fromJson(Object? json, T Function(Object? data) decode) {
    if (json is! Map<String, dynamic> || json['success'] is! bool) {
      throw const FormatException('Not an API envelope');
    }
    final success = json['success'] as bool;
    return ApiResponse(
      success: success,
      code: json['code'] as String? ?? '',
      message: json['message'] as String? ?? '',
      data: success ? decode(json['data']) : null,
    );
  }

  final bool success;
  final String code;
  final String message;
  final T? data;
}
