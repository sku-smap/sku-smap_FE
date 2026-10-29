import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

const _masked = '***';
const _maxBody = 1000;
const _secretKeys = {
  'authorization',
  'cookie',
  'set-cookie',
  'x-admin-key',
  'password',
  'token',
  'accesstoken',
  'refreshtoken',
};

bool _secret(String key) =>
    _secretKeys.contains(key.toLowerCase().replaceAll('_', ''));

// Hide credentials; keep the Bearer scheme so the header still reads
Map<String, Object?> maskHeaders(Map<String, Object?> headers) => {
  for (final MapEntry(:key, :value) in headers.entries)
    key: !_secret(key)
        ? value
        : key.toLowerCase() == 'authorization' && '$value'.startsWith('Bearer ')
        ? 'Bearer $_masked'
        : _masked,
};

// Hide secret fields anywhere in a JSON-like body
Object? maskBody(Object? body) => switch (body) {
  Map() => {
    for (final MapEntry(:key, :value) in body.entries)
      '$key': _secret('$key') ? _masked : maskBody(value),
  },
  List() => [for (final v in body) maskBody(v)],
  FormData() => {
    'fields': maskBody({for (final f in body.fields) f.key: f.value}),
    'files': [for (final f in body.files) '${f.key}: ${f.value.filename}'],
  },
  _ => body,
};

String _clip(Object? body) {
  final text = body is String ? body : jsonEncode(maskBody(body));
  return text.length > _maxBody ? '${text.substring(0, _maxBody)}…' : text;
}

// Dev-only request and response log with secrets masked
class MaskingLogInterceptor extends Interceptor {
  MaskingLogInterceptor({void Function(String line)? log})
    : log = log ?? debugPrint;

  static const _startKey = 'logStart';

  final void Function(String line) log;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();
    log('→ ${options.method} ${options.uri}');
    log('  headers: ${maskHeaders(options.headers)}');
    if (options.data != null) log('  body: ${_clip(options.data)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    final o = response.requestOptions;
    log('← ${response.statusCode} ${o.method} ${o.uri} ${_took(o)}');
    log('  body: ${_clip(response.data)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final o = err.requestOptions;
    final status = err.response?.statusCode ?? err.type.name;
    log('✕ $status ${o.method} ${o.uri} ${_took(o)}');
    if (err.response?.data != null) log('  body: ${_clip(err.response!.data)}');
    handler.next(err);
  }

  String _took(RequestOptions o) {
    final start = o.extra[_startKey] as DateTime?;
    return start == null
        ? ''
        : '(${DateTime.now().difference(start).inMilliseconds}ms)';
  }
}
