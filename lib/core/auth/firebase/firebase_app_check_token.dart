/// SDK-managed App Check token for AI proxy headers.
library;

import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import 'firebase_app_check_bootstrap.dart';

abstract final class FirebaseAppCheckToken {
  FirebaseAppCheckToken._();

  static Future<String?>? _inFlight;
  static bool _loggedEmpty = false;
  static String? _lastError;

  /// Returns a current token from the Firebase App Check SDK, or null.
  /// Never logs the token value.
  static Future<String?> current({bool forceRefresh = false}) {
    if (!FirebaseAppCheckBootstrap.isActivated) {
      print('[AppCheck] getToken skipped — not activated');
      return Future.value(null);
    }
    final active = _inFlight;
    if (active != null && !forceRefresh) return active;
    final future = _fetch(forceRefresh: forceRefresh);
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
  }

  static Future<String?> _fetch({required bool forceRefresh}) async {
    try {
      final token = await FirebaseAppCheck.instance.getToken(forceRefresh);
      final trimmed = token?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        if (!_loggedEmpty) {
          _loggedEmpty = true;
          print('[AppCheck] getToken empty (forceRefresh=$forceRefresh)');
        }
        return null;
      }
      _loggedEmpty = false;
      _lastError = null;
      print(
        '[AppCheck] getToken ok len=${trimmed.length} forceRefresh=$forceRefresh',
      );
      return trimmed;
    } catch (e) {
      final msg = e.toString();
      if (_lastError != msg) {
        _lastError = msg;
        print('[AppCheck] getToken error: $e');
      }
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
