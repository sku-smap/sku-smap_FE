import 'package:flutter/foundation.dart';

import 'app_config.dart';

final _warned = <Type>{};

// Mock while USE_MOCK is on or the feature has no API implementation yet
T selectDataSource<T>(
  AppConfig config, {
  required T Function() mock,
  T Function()? api,
}) {
  if (!config.useMock && api != null) return api();
  if (!config.useMock && _warned.add(T)) {
    debugPrint('[api] $T has no API implementation yet; using mock');
  }
  return mock();
}
