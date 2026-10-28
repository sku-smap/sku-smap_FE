// One error type for every failed request, whatever the cause
sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  // Safe to retry once the cause may have cleared
  bool get retryable => false;

  @override
  String toString() =>
      '$runtimeType(${[?statusCode, ?code, message].join(', ')})';
}

class NetworkException extends AppException {
  const NetworkException([super.message = '인터넷 연결을 확인해 주세요.']);

  @override
  bool get retryable => true;
}

class RequestTimeoutException extends AppException {
  const RequestTimeoutException([
    super.message = '응답이 늦어지고 있어요. 잠시 후 다시 시도해 주세요.',
  ]);

  @override
  bool get retryable => true;
}

class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.statusCode});

  @override
  bool get retryable => (statusCode ?? 0) >= 500;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = '접근 권한이 없어요.', String? code])
    : super(code: code, statusCode: 401);
}

class ParseException extends AppException {
  const ParseException([super.message = '응답을 읽지 못했어요.']);
}

class CancelledException extends AppException {
  const CancelledException() : super('요청이 취소됐어요.');
}

class UnknownException extends AppException {
  const UnknownException([super.message = '문제가 생겼어요. 잠시 후 다시 시도해 주세요.']);
}
