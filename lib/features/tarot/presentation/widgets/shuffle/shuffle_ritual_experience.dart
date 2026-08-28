/// Cinematic shuffle ritual — stack, overhand, optional cut, rest.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/oracly_reduced_motion.dart';
import 'shuffle_cut_motion.dart';
import 'shuffle_ritual_cues.dart';
import 'shuffle_ritual_stage.dart';
import 'shuffle_timeline.dart';

enum _RitualPhase { shuffling, offering, cutting, done }

class ShuffleRitualExperience extends StatefulWidget {
  const ShuffleRitualExperience({
    super.key,
    required this.onComplete,
    this.includeBackgroundDim = true,
  });

  final VoidCallback onComplete;
  final bool includeBackgroundDim;

  @override
  State<ShuffleRitualExperience> createState() =>
      _ShuffleRitualExperienceState();
}

class _ShuffleRitualExperienceState extends State<ShuffleRitualExperience>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _master;
  late final AnimationController _cut;
  _RitualPhase _phase = _RitualPhase.shuffling;
  bool _midCue = false;
  Timer? _offerTimer;
  bool _reducedSettled = false;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: ShuffleTimeline.totalDuration,
    )..addStatusListener(_onShuffleStatus);
    _cut = AnimationController(
      vsync: this,
      duration: ShuffleCutMotion.duration,
    )..addStatusListener(_onCutStatus);
    ShuffleRitualCues.begin();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_phase == _RitualPhase.done) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _master.stop();
      _cut.stop();
    } else if (state == AppLifecycleState.resumed &&
        _phase == _RitualPhase.shuffling &&
        _master.value < 1 &&
        !OraclyReducedMotion.of(context)) {
      _master.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (OraclyReducedMotion.of(context)) {
      if (_reducedSettled) return;
      _reducedSettled = true;
      _midCue = true;
      _master.removeStatusListener(_onShuffleStatus);
      _master.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _finishQuietly();
      });
      return;
    }
    if (_master.status == AnimationStatus.dismissed) {
      _master.forward();
    }
  }

  void _onShuffleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    if (_phase != _RitualPhase.shuffling) return;
    setState(() => _phase = _RitualPhase.offering);
    _offerTimer = Timer(const Duration(milliseconds: 880), _finishQuietly);
  }

  void _onCutStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _finishQuietly();
  }

  void _finishQuietly() {
    _offerTimer?.cancel();
    if (_phase == _RitualPhase.done) return;
    _phase = _RitualPhase.done;
    if (mounted) widget.onComplete();
  }

  void _cutDeck() {
    if (_phase != _RitualPhase.offering) return;
    _offerTimer?.cancel();
    ShuffleRitualCues.cut();
    setState(() => _phase = _RitualPhase.cutting);
    _cut.forward();
  }

  void _maybeMidCue(double t) {
    if (_midCue || t < 0.40) return;
    _midCue = true;
    ShuffleRitualCues.midShuffle();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _offerTimer?.cancel();
    _master.dispose();
    _cut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_phase == _RitualPhase.shuffling && _master.value >= 0.55) {
          _finishQuietly();
        }
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_master, _cut]),
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(
            _master.value.clamp(0.0, 1.0),
          );
          _maybeMidCue(t);
          return ShuffleRitualStage(
            progress: t,
            cutProgress: _cut.value,
            dim: widget.includeBackgroundDim,
            offering: _phase == _RitualPhase.offering,
            onCut: _cutDeck,
            onSkip: _finishQuietly,
          );
        },
      ),
    );
  }
}
