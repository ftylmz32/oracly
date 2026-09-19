/// Activates Firebase App Check after [FirebaseAuthBootstrap] succeeds.
library;

import 'dart:async';

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
  static Future<bool>? _inFlight;

  static bool get isActivated => _activated;

  /// Call only after Firebase Core is ready. Failures are swallowed;
  /// production AI fail-closes later when no token can be obtained.
  static Future<bool> tryActivate({
    AppEnvironment? environment,
    bool? releaseLocked,
  }) {
    if (_activated) return Future.value(true);
    final active = _inFlight;
    if (active != null) return active;
    final future = _activateOnce(
      environment: environment,
      releaseLocked: releaseLocked,
    );
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
  }

  static Future<bool> _activateOnce({
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
      print(
        '[AppCheck] activated debug=$debug env=${env.name} locked=$locked',
      );
    } catch (e) {
      _activated = false;
      print('[AppCheck] activate failed: $e');
    }
    return _activated;
  }

  /// Dart-define is authoritative — it's what the rest of the AI runtime
  /// ([OraclyRuntimeConfig]/[AiRuntimeConfig]) resolves environment from.
  @visibleForTesting
  static AppEnvironment resolveEnvironment() => _resolveEnvironment();

  static AppEnvironment _resolveEnvironment() {
    final raw = OraclyRuntimeConfig.readRaw(OraclyRuntimeKeys.appEnv);
    if (raw != null) return AppEnvironment.fromString(raw);
    if (AppConfig.isInitialized) {
      return AppConfig.instance.environment;
    }
    return AppEnvironment.development;
  }

  @visibleForTesting
  static void debugSetActivated(bool value) => _activated = value;

  static void reset() {
    _activated = false;
    _inFlight = null;
  }
}
