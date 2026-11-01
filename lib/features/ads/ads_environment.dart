/// Which AdMob app the native build carries.
///
/// Debug / profile builds carry Google's official sample app ids (set in
/// android/app/build.gradle.kts and ios/Flutter/Debug.xcconfig) and may
/// only ever load Google's test ads. A release build carries a real app id
/// only when the protected build environment supplies one; the native
/// builds refuse to produce a release without it, and this Dart side also
/// refuses to prepare ads unless the same real id is passed as a define.
library;

import 'package:flutter/foundation.dart';

class AdsEnvironment {
  const AdsEnvironment({
    required this.supportedPlatform,
    required this.appIdConfigured,
  });

  /// Google's published sample publisher — test ads only.
  static const googleTestPublisher = 'ca-app-pub-3940256099942544';

  static const _androidReleaseAppId = String.fromEnvironment(
    'ORACLY_ADMOB_ANDROID_APP_ID',
  );
  static const _iosReleaseAppId = String.fromEnvironment(
    'ORACLY_ADMOB_IOS_APP_ID',
  );

  static final _realAppId = RegExp(r'^ca-app-pub-\d{16}~\d{10}$');

  /// True for a real (non-sample) AdMob app id.
  static bool isRealAppId(String id) =>
      _realAppId.hasMatch(id) && !id.startsWith(googleTestPublisher);

  final bool supportedPlatform;
  final bool appIdConfigured;

  bool get usable => supportedPlatform && appIdConfigured;

  static AdsEnvironment current() => resolve(
    platform: defaultTargetPlatform,
    web: kIsWeb,
    releaseMode: kReleaseMode,
    androidReleaseAppId: _androidReleaseAppId,
    iosReleaseAppId: _iosReleaseAppId,
  );

  @visibleForTesting
  static AdsEnvironment resolve({
    required TargetPlatform platform,
    required bool web,
    required bool releaseMode,
    String androidReleaseAppId = '',
    String iosReleaseAppId = '',
  }) {
    final supported =
        !web &&
        (platform == TargetPlatform.android || platform == TargetPlatform.iOS);
    if (!supported) {
      return const AdsEnvironment(
        supportedPlatform: false,
        appIdConfigured: false,
      );
    }
    // Non-release builds carry the sample app id natively.
    if (!releaseMode) {
      return const AdsEnvironment(
        supportedPlatform: true,
        appIdConfigured: true,
      );
    }
    final id = platform == TargetPlatform.android
        ? androidReleaseAppId
        : iosReleaseAppId;
    return AdsEnvironment(
      supportedPlatform: true,
      appIdConfigured: isRealAppId(id),
    );
  }
}
