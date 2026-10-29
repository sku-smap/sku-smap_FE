import 'package:dio/dio.dart';

// Headers every request carries; only CORS-safelisted ones, so browsers send
// GETs without a preflight
class HeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent('Accept', () => 'application/json');
    options.headers.putIfAbsent('Accept-Language', () => 'ko-KR');
    handler.next(options);
  }
}
