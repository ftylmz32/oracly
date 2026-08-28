/// SDK-managed App Check token for AI proxy headers.
library;

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import 'firebase_app_check_bootstrap.dart';

abstract final class FirebaseAppCheckToken {
  FirebaseAppCheckToken._();

  /// Returns a current token from the Firebase App Check SDK, or null.
  /// Never logs the token value.
  static Future<String?> current({bool forceRefresh = false}) async {
    if (!FirebaseAppCheckBootstrap.isActivated) return null;
    try {
      final token = await FirebaseAppCheck.instance.getToken(forceRefresh);
      final trimmed = token?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return trimmed;
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static Future<String?> Function()? debugOverride;

  static Future<String?> resolve({bool forceRefresh = false}) {
    final override = debugOverride;
    if (override != null) return override();
    return current(forceRefresh: forceRefresh);
  }
}
