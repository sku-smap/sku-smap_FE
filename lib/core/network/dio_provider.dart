import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'app_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/header_interceptor.dart';
import 'interceptors/log_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

// No sign-in yet; a session store replaces this when one exists
final accessTokenReaderProvider = Provider<AccessTokenReader>(
  (ref) =>
      () async => null,
);

Dio buildDio(AppConfig config, {required AccessTokenReader readToken}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: config.sendTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.addAll([
    HeaderInterceptor(),
    AuthInterceptor(readToken),
    RetryInterceptor(dio),
    if (config.logNetwork) MaskingLogInterceptor(),
  ]);
  return dio;
}

final dioProvider = Provider<Dio>((ref) {
  final dio = buildDio(
    ref.watch(appConfigProvider),
    readToken: ref.watch(accessTokenReaderProvider),
  );
  ref.onDispose(dio.close);
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
