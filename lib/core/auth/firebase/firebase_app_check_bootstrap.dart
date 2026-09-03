/// Activates Firebase App Check after [FirebaseAuthBootstrap] succeeds.
library;

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '../../config/app_config.dart';
import '../../config/app_environment.dart';
import '../../config/oracly_runtime_config.dart';
import '../../config/oracly_runtime_keys.dart';
import 'firebase_app_check_policy.dart';
import 'firebase_auth_bootstrap.dart';

abstract final class FirebaseAppCheckBootstrap {
  FirebaseAppCheckBootstrap._();

  static bool _activated = false;

  static bool get isActivated => _activated;

  /// Call only after Firebase Core is ready. Failures are swallowed;
  /// production AI fail-closes later when no token can be obtained.
  static Future<bool> tryActivate({
    AppEnvironment? environment,
    bool? releaseLocked,
  }) async {
    if (_activated) return true;
    if (!FirebaseAuthBootstrap.isReady) return false;
    final env = environment ?? _resolveEnvironment();
    final locked = releaseLocked ?? kReleaseMode;
    final debug = FirebaseAppCheckPolicy.useDebugProvider(
      environment: env,
      releaseLocked: locked,
    );
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: debug
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: debug
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
      _activated = true;
    } catch (_) {
      _activated = false;
    }
    return _activated;
  }

  static AppEnvironment _resolveEnvironment() {
    if (AppConfig.isInitialized) {
      return AppConfig.instance.environment;
    }
    return AppEnvironment.fromString(
      OraclyRuntimeConfig.readRaw(OraclyRuntimeKeys.appEnv),
    );
  }

  @visibleForTesting
  static void debugSetActivated(bool value) => _activated = value;

  static void reset() => _activated = false;
}
