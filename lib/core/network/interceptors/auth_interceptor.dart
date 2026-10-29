import 'package:dio/dio.dart';

typedef AccessTokenReader = Future<String?> Function();

// Bearer token when one exists; the app has no sign-in yet
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.readToken);

  final AccessTokenReader readToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
