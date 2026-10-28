import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// Headers every request carries
class HeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent('Accept', () => 'application/json');
    options.headers.putIfAbsent('Accept-Language', () => 'ko-KR');
    options.headers.putIfAbsent(
      'X-Client-Platform',
      () => kIsWeb ? 'web' : defaultTargetPlatform.name,
    );
    handler.next(options);
  }
}
