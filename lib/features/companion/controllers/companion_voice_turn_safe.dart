/// Safe notify helpers for voice-turn ChangeNotifiers.
library;

import 'package:flutter/foundation.dart';

mixin CompanionVoiceTurnSafe on ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  @protected
  void markDisposed() => _disposed = true;

  @protected
  void safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }
}
