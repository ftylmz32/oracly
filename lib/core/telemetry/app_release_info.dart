/// Release metadata for crash reports — sync with pubspec version.
library;

import 'package:flutter/foundation.dart';

abstract final class AppReleaseInfo {
  AppReleaseInfo._();

  static const version = '1.0.0';
  static const buildNumber = '1';

  static String get applicationId => switch (defaultTargetPlatform) {
        TargetPlatform.android => 'app.oracly',
        TargetPlatform.iOS => 'com.example.oraclyNew',
        _ => 'app.oracly',
      };

  static String get platform => switch (defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.iOS => 'ios',
        TargetPlatform.macOS => 'macos',
        TargetPlatform.windows => 'windows',
        TargetPlatform.linux => 'linux',
        TargetPlatform.fuchsia => 'fuchsia',
      };

  static String get deviceCategory => kIsWeb
      ? 'web'
      : switch (defaultTargetPlatform) {
          TargetPlatform.android || TargetPlatform.iOS => 'mobile',
          TargetPlatform.macOS ||
          TargetPlatform.windows ||
          TargetPlatform.linux =>
            'desktop',
          TargetPlatform.fuchsia => 'embedded',
        };
}
