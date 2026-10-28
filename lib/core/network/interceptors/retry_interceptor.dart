import 'package:dio/dio.dart';

// Retry idempotent requests that failed before reaching the server
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this.dio, {
    this.maxRetries = 2,
    Duration Function(int attempt)? backoff,
  }) : backoff =
           backoff ??
           ((attempt) => Duration(milliseconds: 300 * (1 << attempt)));

  static const _attemptKey = 'retryAttempt';
  static const _idempotent = {'GET', 'HEAD', 'PUT', 'DELETE', 'OPTIONS'};

  final Dio dio;
  final int maxRetries;
  final Duration Function(int attempt) backoff;

  bool _shouldRetry(DioException e) =>
      _idempotent.contains(e.requestOptions.method.toUpperCase()) &&
      switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.connectionError => true,
        DioExceptionType.badResponse =>
          (e.response?.statusCode ?? 0) >= 502 &&
              (e.response?.statusCode ?? 0) <= 504,
        _ => false,
      };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = options.extra[_attemptKey] as int? ?? 0;
    if (!_shouldRetry(err) || attempt >= maxRetries) {
      return handler.next(err);
    }
    await Future<void>.delayed(backoff(attempt));
    try {
      options.extra[_attemptKey] = attempt + 1;
      handler.resolve(await dio.fetch<Object?>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
