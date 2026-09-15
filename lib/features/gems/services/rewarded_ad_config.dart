import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract final class RewardedAdConfig {
  static const _androidTest = 'ca-app-pub-3940256099942544/5224354917';
  static const _iosTest = 'ca-app-pub-3940256099942544/1712485313';
  static const _androidProduction = String.fromEnvironment('ORACLY_ADMOB_REWARDED_ANDROID_ID');
  static const _iosProduction = String.fromEnvironment('ORACLY_ADMOB_REWARDED_IOS_ID');

  static String? unitId({TargetPlatform? platform, bool? releaseMode}) {
    final target = platform ?? defaultTargetPlatform;
    if (target != TargetPlatform.android && target != TargetPlatform.iOS) return null;
    final release = releaseMode ?? kReleaseMode;
    if (!release) return target == TargetPlatform.android ? _androidTest : _iosTest;
    final configured = target == TargetPlatform.android ? _androidProduction : _iosProduction;
    return configured.startsWith('ca-app-pub-') && !configured.contains('3940256099942544') ? configured : null;
  }
}
