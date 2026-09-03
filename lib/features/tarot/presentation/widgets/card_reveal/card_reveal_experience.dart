/// OR-1050+ — Cinematic card reveal orchestrator.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/oracly_reduced_motion.dart';
import '../../../../../shared/widgets/oracly_pressable.dart';
import 'card_reveal_spread.dart';
import 'card_reveal_stage.dart';
import 'reveal_sound_callbacks.dart';
import 'reveal_timeline.dart';

class CardRevealExperience extends StatefulWidget {
  const CardRevealExperience({
    super.key,
    required this.data,
    required this.onContinue,
    this.startProgress = 0,
    this.soundCallbacks = RevealSoundCallbacks.silent,
    this.completionHint,
    this.continueBusy = false,
    this.continueError,
  });

  final RevealCardData data;
  final VoidCallback onContinue;
  final double startProgress;
  final RevealSoundCallbacks soundCallbacks;
  final String? completionHint;
  final bool continueBusy;
  final String? continueError;

  @override
  State<CardRevealExperience> createState() => _CardRevealExperienceState();
}

class _CardRevealExperienceState extends State<CardRevealExperience>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _master;
  late final RevealSoundCallbackTracker _soundTracker;
  bool _hapticFlip = false;
  bool _hapticReveal = false;
  bool _reducedSettled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _soundTracker = RevealSoundCallbackTracker(widget.soundCallbacks);
    _master = AnimationController(
      vsync: this,
      duration: RevealTimeline.totalDuration,
      value: widget.startProgress.clamp(0.0, 1.0),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_reducedSettled) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _master.stop();
    } else if (state == AppLifecycleState.resumed &&
        _master.value < 1 &&
        !_reducedSettled &&
        !OraclyReducedMotion.of(context)) {
      _master.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (OraclyReducedMotion.of(context)) {
      _master.value = 1;
      if (_reducedSettled) return;
      _reducedSettled = true;
      widget.soundCallbacks.onBloomPeak?.call();
      OraclyTouchFeedback.reveal();
      return;
    }
    if (_master.status == AnimationStatus.dismissed ||
        (_master.value > 0 && _master.value < 1 && !_master.isAnimating)) {
      _master.forward();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _master.dispose();
    super.dispose();
  }

  void _maybeHaptics(double t) {
    if (!_hapticFlip && t >= RevealTimeline.flipStart) {
      _hapticFlip = true;
      OraclyTouchFeedback.selection();
    }
    if (!_hapticReveal && t >= RevealTimeline.flipEnd + 0.08) {
      _hapticReveal = true;
      OraclyTouchFeedback.reveal();
    }
  }

  void _skipToContinue() {
    if (_master.value >= RevealTimeline.flipEnd) {
      _master.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _skipToContinue,
      child: AnimatedBuilder(
        animation: _master,
        builder: (context, _) {
          final t = _master.value;
          if (!_reducedSettled) {
            _soundTracker.tick(t);
            _maybeHaptics(t);
          }
          return CardRevealStage(
            progress: t,
            data: widget.data,
            onContinue: widget.onContinue,
            completionHint: widget.completionHint,
            continueBusy: widget.continueBusy,
            continueError: widget.continueError,
          );
        },
      ),
    );
  }
}
