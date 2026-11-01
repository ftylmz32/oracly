/// Which AdMob app the native build carries, and whether this build may
/// prepare ads at all.
///
/// Debug / profile builds carry Google's official sample app ids (set in
/// android/app/build.gradle.kts and ios/Flutter/Debug.xcconfig) and may
/// only ever load Google's test ads. Release builds carry ORACLY's real
/// AdMob app ids (app ids, not ad unit ids; build.gradle.kts and
/// ios/Flutter/Release.xcconfig hold the same values as below).
///
/// A real app id alone never enables ads. A release build additionally
/// needs the explicit, PO-approved build define ORACLY_ADS_RELEASE_APPROVED
/// (default false) — set only once the UMP consent message is published,
/// ad units exist and production ads are approved. Without it the gate is
/// notConfigured in release even if the remote ads_v1 flag is turned on.
library;

import 'package:flutter/foundation.dart';

class AdsEnvironment {
  const AdsEnvironment({
    required this.supportedPlatform,
    required this.appIdConfigured,
    this.releaseApproved = true,
  });

  /// Google's published sample publisher — test ads only.
  static const googleTestPublisher = 'ca-app-pub-3940256099942544';

  /// ORACLY's AdMob app ids (verified in the AdMob console by the PO).
  static const androidProductionAppId =
      'ca-app-pub-8094570449180229~6192956874';
  static const iosProductionAppId = 'ca-app-pub-8094570449180229~5809813493';

  /// Explicit production-ads approval baked into a release build.
  static const releaseApprovedDefine = bool.fromEnvironment(
    'ORACLY_ADS_RELEASE_APPROVED',
  );

  static final _realAppId = RegExp(r'^ca-app-pub-\d{16}~\d{10}$');

  /// True for a real (non-sample) AdMob app id.
  static bool isRealAppId(String id) =>
      _realAppId.hasMatch(id) && !id.startsWith(googleTestPublisher);

  final bool supportedPlatform;
  final bool appIdConfigured;

  /// Non-release builds: always true (sample app id, test ads only).
  /// Release builds: only with ORACLY_ADS_RELEASE_APPROVED=true.
  final bool releaseApproved;

  bool get usable => supportedPlatform && appIdConfigured && releaseApproved;

  static AdsEnvironment current() => resolve(
    platform: defaultTargetPlatform,
    web: kIsWeb,
    releaseMode: kReleaseMode,
    releaseApproved: releaseApprovedDefine,
  );

  @visibleForTesting
  static AdsEnvironment resolve({
    required TargetPlatform platform,
    required bool web,
    required bool releaseMode,
    bool releaseApproved = false,
    String androidReleaseAppId = androidProductionAppId,
    String iosReleaseAppId = iosProductionAppId,
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
      releaseApproved: releaseApproved,
    );
  }
}
