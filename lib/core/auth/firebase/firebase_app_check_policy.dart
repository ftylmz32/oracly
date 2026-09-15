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

  /// Debug provider for any non-release-locked build, regardless of
  /// [environment]. Play Integrity / App Attest require the app to be
  /// recognized by Google Play or notarized by Apple; a debug build
  /// (including an internal/staging sideload for QA or store review) is
  /// neither, so it cannot earn a real attestation verdict — only a
  /// release-locked build (real Play/App Store distribution) can.
  /// Never silently activate in release / release-locked builds.
  static bool useDebugProvider({
    required AppEnvironment environment,
    required bool releaseLocked,
  }) {
    return !releaseLocked;
  }
}
