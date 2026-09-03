/// Resolves whether the running app must use real auth (not MockAuth).
library;

import 'package:flutter/foundation.dart';

import '../config/app_environment.dart';
import '../config/oracly_runtime_config.dart';
import '../config/oracly_runtime_keys.dart';

abstract final class AuthRuntime {
  AuthRuntime._();

  static bool get isProductionLike {
    if (kReleaseMode) return true;
    final resolved = AppEnvironment.fromString(
      OraclyRuntimeConfig.readRaw(OraclyRuntimeKeys.appEnv),
    );
    return !resolved.isDevelopment;
  }
}