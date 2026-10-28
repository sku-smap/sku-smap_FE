import 'package:dio/dio.dart';

import 'api_response.dart';
import 'app_exception.dart';
import 'error_mapper.dart';

typedef JsonDecoder<T> = T Function(Object? data);

// Unwraps the envelope and throws only AppException
class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, Object?>? query,
    required JsonDecoder<T> decode,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.get<Object?>(
      path,
      queryParameters: query,
      cancelToken: cancelToken,
    ),
    decode,
  );

  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, Object?>? query,
    required JsonDecoder<T> decode,
    CancelToken? cancelToken,
    Options? options,
  }) => _send(
    () => _dio.post<Object?>(
      path,
      data: body,
      queryParameters: query,
      cancelToken: cancelToken,
      options: options,
    ),
    decode,
  );

  Future<T> put<T>(
    String path, {
    Object? body,
    required JsonDecoder<T> decode,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.put<Object?>(path, data: body, cancelToken: cancelToken),
    decode,
  );

  Future<T> delete<T>(
    String path, {
    Object? body,
    required JsonDecoder<T> decode,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.delete<Object?>(path, data: body, cancelToken: cancelToken),
    decode,
  );

  // Multipart upload such as a recorded voice question
  Future<T> postForm<T>(
    String path, {
    required FormData form,
    required JsonDecoder<T> decode,
    CancelToken? cancelToken,
    Duration? sendTimeout,
  }) => _send(
    () => _dio.post<Object?>(
      path,
      data: form,
      cancelToken: cancelToken,
      options: Options(
        contentType: Headers.multipartFormDataContentType,
        sendTimeout: sendTimeout,
      ),
    ),
    decode,
  );

  Future<T> _send<T>(
    Future<Response<Object?>> Function() request,
    JsonDecoder<T> decode,
  ) async {
    final ApiResponse<T> envelope;
    try {
      final response = await request();
      envelope = ApiResponse.fromJson(response.data, decode);
    } on Object catch (e) {
      throw toAppException(e);
    }
    if (!envelope.success) {
      throw ServerException(envelope.message, code: envelope.code);
    }
    return envelope.data as T;
  }
}

// For endpoints whose data is null or not needed
void ignoreData(Object? _) {}
