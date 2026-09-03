/// FinalOraclySplash — one full-screen source art, ~1.9s, over destination.
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import 'splash_completion_gate.dart';
import 'splash_final_stage.dart';
import 'splash_final_timeline.dart';
import 'splash_startup_log.dart';

/// Canonical name for the final single-image Flutter splash.
typedef FinalOraclySplash = SplashBrandOverlay;

class SplashBrandOverlay extends StatefulWidget {
  const SplashBrandOverlay({
    super.key,
    required this.onDone,
    this.reduced = false,
    this.onFirstFrame,
  });

  final VoidCallback onDone;
  final bool reduced;

  /// Fired once after the overlay's first Flutter frame (destination may mount).
  final VoidCallback? onFirstFrame;

  static const durationMs = SplashFinalTimeline.durationMs;
  static const reducedMs = SplashFinalTimeline.reducedMs;

  @override
  State<SplashBrandOverlay> createState() => _SplashBrandOverlayState();
}

class _SplashBrandOverlayState extends State<SplashBrandOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _gate = SplashCompletionGate();
  bool _done = false;
  bool _firstFrameLogged = false;
  bool _precacheStarted = false;

  @override
  void initState() {
    super.initState();
    SplashStartupLog.mark('FINAL_SPLASH_INIT');
    _c =
        AnimationController(
          vsync: this,
          duration: Duration(
            milliseconds: widget.reduced
                ? SplashBrandOverlay.reducedMs
                : SplashBrandOverlay.durationMs,
          ),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed) {
            SplashStartupLog.mark('FINAL_SPLASH_ANIMATION_END');
            if (_gate.requestFinish()) _finish();
          }
        });
    SplashStartupLog.mark('FINAL_SPLASH_ANIMATION_START');
    _c.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _signalFirstFrame());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precacheStarted) return;
    _precacheStarted = true;
    precacheImage(const AssetImage(AppAssets.splashFinal), context);
  }

  void _signalFirstFrame() {
    if (_firstFrameLogged) return;
    _firstFrameLogged = true;
    SplashStartupLog.mark('FINAL_SPLASH_FIRST_BUILD');
    widget.onFirstFrame?.call();
  }

  void _onArtPainted() {
    if (_gate.artPainted) return;
    SplashStartupLog.mark('FINAL_SPLASH_ART_PAINTED');
    if (_gate.onArtSettled(painted: true)) _finish();
  }

  void _onArtFailed() {
    if (_gate.artFailed || _gate.artPainted) return;
    SplashStartupLog.mark('FINAL_SPLASH_ART_FAILED');
    if (_gate.onArtSettled(painted: false)) _finish();
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    SplashStartupLog.mark('FINAL_SPLASH_REMOVED');
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => SplashFinalStage(
        t: _c.value,
        reduced: widget.reduced,
        onArtPainted: _onArtPainted,
        onArtFailed: _onArtFailed,
      ),
    );
  }
}
