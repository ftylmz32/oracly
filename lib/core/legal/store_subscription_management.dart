/// Official App Store / Play subscription management entry points.
library;

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

enum StoreManageResult { opened, unavailable, launchFailed }

abstract final class StoreSubscriptionManagement {
  StoreSubscriptionManagement._();

  static const androidPackageId = 'app.oracly';

  static Uri uriFor({TargetPlatform? platform}) {
    final p = platform ?? defaultTargetPlatform;
    if (p == TargetPlatform.iOS || p == TargetPlatform.macOS) {
      return Uri.parse('https://apps.apple.com/account/subscriptions');
    }
    return Uri.parse(
      'https://play.google.com/store/account/subscriptions'
      '?package=$androidPackageId',
    );
  }

  static bool isAvailable({TargetPlatform? platform}) {
    final p = platform ?? defaultTargetPlatform;
    return p == TargetPlatform.iOS ||
        p == TargetPlatform.macOS ||
        p == TargetPlatform.android;
  }

  static Future<StoreManageResult> open({TargetPlatform? platform}) async {
    if (!isAvailable(platform: platform)) {
      return StoreManageResult.unavailable;
    }
    try {
      final ok = await launchUrl(
        uriFor(platform: platform),
        mode: LaunchMode.externalApplication,
      );
      return ok ? StoreManageResult.opened : StoreManageResult.launchFailed;
    } catch (_) {
      return StoreManageResult.launchFailed;
    }
  }
}