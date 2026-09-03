/// OR-1050+ — Sound-ready animation hooks for card reveal (no audio yet).
library;

import 'package:flutter/foundation.dart';

import 'reveal_timeline.dart';

/// Lifecycle hooks for future SFX integration.
@immutable
class RevealSoundCallbacks {
  const RevealSoundCallbacks({
    this.onRevealStart,
    this.onAmbientDeepen,
    this.onFlipStart,
    this.onFlipMidpoint,
    this.onFlipComplete,
    this.onBloomPeak,
    this.onMetaReveal,
    this.onRevealComplete,
  });

  final VoidCallback? onRevealStart;
  final VoidCallback? onAmbientDeepen;
  final VoidCallback? onFlipStart;
  final VoidCallback? onFlipMidpoint;
  final VoidCallback? onFlipComplete;
  final VoidCallback? onBloomPeak;
  final VoidCallback? onMetaReveal;
  final VoidCallback? onRevealComplete;

  static const silent = RevealSoundCallbacks();
}

/// Fires each callback at most once per reveal sequence.
class RevealSoundCallbackTracker {
  RevealSoundCallbackTracker(this.callbacks);

  final RevealSoundCallbacks callbacks;
  final _fired = <String>{};

  void tick(double t) {
    _once('start', t >= 0.02, callbacks.onRevealStart);
    _once('ambient', t >= 0.12, callbacks.onAmbientDeepen);
    _once('flipStart', t >= RevealTimeline.flipStart, callbacks.onFlipStart);
    _once(
      'flipMid',
      t >= RevealTimeline.flipStart + 0.12,
      callbacks.onFlipMidpoint,
    );
    _once('flipDone', t >= RevealTimeline.flipEnd, callbacks.onFlipComplete);
    _once('bloom', t >= RevealTimeline.flipEnd + 0.08, callbacks.onBloomPeak);
    _once('meta', t >= RevealTimeline.flipEnd + 0.14, callbacks.onMetaReveal);
    _once('done', t >= 0.99, callbacks.onRevealComplete);
  }

  void _once(String key, bool condition, VoidCallback? cb) {
    if (condition && _fired.add(key)) cb?.call();
  }

  void reset() => _fired.clear();
}
