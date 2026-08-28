/// When App Check is required vs when the debug provider may be used.
library;

import '../../config/app_environment.dart';

abstract final class FirebaseAppCheckPolicy {
  FirebaseAppCheckPolicy._();

  /// Production/staging (and release-locked builds) require a token on proxy AI.
  static bool requiresToken({
    required AppEnvironment environment,
    required bool usesProxy,
    required bool releaseLocked,
  }) {
    if (!usesProxy) return false;
    if (releaseLocked) return true;
    return !environment.isDevelopment;
  }

  /// Debug provider only for explicit non-release development.
  /// Never silently activate in release / release-locked builds.
  static bool useDebugProvider({
    required AppEnvironment environment,
    required bool releaseLocked,
  }) {
    if (releaseLocked) return false;
    return environment.isDevelopment;
  }
}
