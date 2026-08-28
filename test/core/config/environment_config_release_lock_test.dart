/// Release API base URL must reject localhost / plain HTTP.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/config/environment_config.dart';

void main() {
  test('production defaults to HTTPS API host', () {
    final cfg = EnvironmentConfig.fromEnv({
      'APP_ENV': 'production',
    });
    expect(cfg.environment, AppEnvironment.production);
    expect(cfg.apiBaseUrl, startsWith('https://'));
    expect(cfg.apiBaseUrl.contains('localhost'), isFalse);
  });

  test('production rejects localhost API_BASE_URL override', () {
    final cfg = EnvironmentConfig.fromEnv({
      'APP_ENV': 'production',
      'API_BASE_URL': 'http://127.0.0.1:8080',
    });
    expect(cfg.apiBaseUrl, 'https://api.oracly.app');
  });

  test('development may keep localhost', () {
    final cfg = EnvironmentConfig.fromEnv({
      'APP_ENV': 'development',
      'API_BASE_URL': 'http://localhost:8080',
    });
    if (kReleaseMode) {
      expect(cfg.apiBaseUrl, startsWith('https://'));
    } else {
      expect(cfg.apiBaseUrl, 'http://localhost:8080');
    }
  });
}
