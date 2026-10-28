import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnv { dev, prod }

// Build settings from --dart-define-from-file=env/<env>.json
class AppConfig {
  const AppConfig({
    required this.env,
    required this.baseUrl,
    required this.useMock,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 15),
  });

  factory AppConfig.fromEnvironment() {
    const env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.milkyway03.cloud',
    );
    const useMock = String.fromEnvironment('USE_MOCK', defaultValue: 'true');
    return AppConfig(
      env: AppEnv.values.where((e) => e.name == env).firstOrNull ?? AppEnv.dev,
      baseUrl: baseUrl,
      useMock: useMock != 'false',
    );
  }

  final AppEnv env;
  final String baseUrl;
  final bool useMock;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  // Request logs only in dev debug builds
  bool get logNetwork => env == AppEnv.dev && kDebugMode;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
