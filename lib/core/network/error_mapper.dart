import 'package:dio/dio.dart';

import 'app_exception.dart';

// Turn a Dio failure, error envelope or bad body into an AppException
AppException toAppException(Object error) {
  if (error is AppException) return error;
  if (error is FormatException || error is TypeError) {
    return const ParseException();
  }
  if (error is! DioException) return const UnknownException();
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const RequestTimeoutException(),
    DioExceptionType.connectionError => const NetworkException(),
    DioExceptionType.cancel => const CancelledException(),
    DioExceptionType.badResponse => _fromResponse(error.response),
    DioExceptionType.badCertificate || DioExceptionType.unknown =>
      error.error is AppException
          ? error.error! as AppException
          : const NetworkException(),
  };
}

AppException _fromResponse(Response<Object?>? response) {
  final status = response?.statusCode;
  final body = response?.data;
  final code = body is Map ? body['code'] as String? : null;
  final message = body is Map ? body['message'] as String? : null;
  if (status == 401) {
    return UnauthorizedException(message ?? '접근 권한이 없어요.', code);
  }
  return ServerException(
    message ?? '서버에 문제가 생겼어요. 잠시 후 다시 시도해 주세요.',
    code: code,
    statusCode: status,
  );
}
