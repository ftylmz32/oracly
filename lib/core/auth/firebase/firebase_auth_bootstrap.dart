/// Attempts native Firebase initialization. No invented project options.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class FirebaseAuthBootstrap {
  FirebaseAuthBootstrap._();

  static bool _ready = false;
  static Future<bool>? _inFlight;

  /// Riverpod-safe signal — flips when [tryInitialize] finishes.
  static final ValueNotifier<bool> ready = ValueNotifier<bool>(false);

  static bool get isReady => _ready;

  /// Succeeds only when a real Firebase app can initialize
  /// (`google-services.json` / `GoogleService-Info.plist` / existing app).
  static Future<bool> tryInitialize() async {
    if (_ready || Firebase.apps.isNotEmpty) {
      _setReady(true);
      return true;
    }
    final existing = _inFlight;
    if (existing != null) return existing;
    final future = _initializeOnce();
    _inFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlight, future)) _inFlight = null;
    }
  }

  static Future<bool> _initializeOnce() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _setReady(Firebase.apps.isNotEmpty);
    } catch (_) {
      _setReady(false);
    }
    return _ready;
  }

  static void _setReady(bool value) {
    _ready = value;
    if (ready.value != value) ready.value = value;
  }

  @visibleForTesting
  static void debugSetReady(bool value) => _setReady(value);

  static void reset() {
    _inFlight = null;
    _setReady(false);
  }
}
