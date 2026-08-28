/// Attempts native Firebase initialization. No invented project options.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class FirebaseAuthBootstrap {
  FirebaseAuthBootstrap._();

  static bool _ready = false;

  static bool get isReady => _ready;

  /// Succeeds only when a real Firebase app can initialize
  /// (`google-services.json` / `GoogleService-Info.plist` / existing app).
  static Future<bool> tryInitialize() async {
    if (Firebase.apps.isNotEmpty) {
      _ready = true;
      return true;
    }
    try {
      await Firebase.initializeApp();
      _ready = Firebase.apps.isNotEmpty;
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  @visibleForTesting
  static void debugSetReady(bool value) => _ready = value;

  static void reset() => _ready = false;
}
