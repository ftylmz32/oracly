/// Regression: App Check env resolution must agree with the AI runtime's
/// dart-define-aware config, not silently fall back to dotenv-only state.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/firebase/firebase_app_check_bootstrap.dart';
import 'package:oracly_new/core/config/app_config.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/config/environment_config.dart';
import 'package:oracly_new/core/config/oracly_runtime_config.dart';

void main() {
  tearDown(() {
    OraclyRuntimeConfig.testEnv = null;
    AppConfig.reset();
  });

  test(
    'resolves staging from the dart-define even when AppConfig (dotenv-only) '
    'still reports development — this is the exact device-observed bug: '
    '`--dart-define=APP_ENV=internal` picked the debug App Check provider '
    'because AppConfig disagreed with OraclyRuntimeConfig',
    () async {
      OraclyRuntimeConfig.testEnv = const {'APP_ENV': 'internal'};
      await AppConfig.initialize(EnvironmentConfig.fromEnv(const {}));
      expect(AppConfig.instance.environment, AppEnvironment.development);

      expect(
        FirebaseAppCheckBootstrap.resolveEnvironment(),
        AppEnvironment.staging,
      );
    },
  );

  test(
    'falls back to AppConfig when no dart-define/dotenv APP_ENV is set',
    () async {
      await AppConfig.initialize(
        EnvironmentConfig.fromEnv(const {'APP_ENV': 'production'}),
      );
      expect(
        FirebaseAppCheckBootstrap.resolveEnvironment(),
        AppEnvironment.production,
      );
    },
  );

  test(
    'defaults to development when neither source is configured',
    () {
      expect(
        FirebaseAppCheckBootstrap.resolveEnvironment(),
        AppEnvironment.development,
      );
    },
  );
}
