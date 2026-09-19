/// When App Check is required vs when the debug provider may be used.
library;

import '../../config/app_environment.dart';

abstract final class FirebaseAppCheckPolicy {
  FirebaseAppCheckPolicy._();

  /// Explicit QA opt-in for sideloaded release builds. Still requires a real
  /// App Check token (debug token must be registered in Firebase Console).
  /// Never set in store `dart_defines.production.json`.
  static const forceDebugProvider = bool.fromEnvironment(
    'ORACLY_APP_CHECK_DEBUG_PROVIDER',
  );

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
  ///
  /// [forceDebugProvider] is the only release-locked exception: sideload QA
  /// that still mints and sends App Check tokens (never a bypass).
  static bool useDebugProvider({
    required AppEnvironment environment,
    required bool releaseLocked,
  }) {
    if (forceDebugProvider) return true;
    return !releaseLocked;
  }
}
