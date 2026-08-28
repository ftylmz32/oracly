/// OR Living Core — canonical celestial presence emblem.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/oracly_quiet_motion.dart';
import 'companion_or_living_core_painter.dart';
import 'companion_or_living_tokens.dart';
import 'companion_or_presence.dart';

class CompanionOrLivingCore extends StatefulWidget {
  const CompanionOrLivingCore({
    super.key,
    required this.size,
    this.breathe = true,
    this.presence = CompanionOrPresence.idle,
    this.compact = false,
  });

  final double size;
  final bool breathe;
  final CompanionOrPresence presence;
  final bool compact;

  @override
  State<CompanionOrLivingCore> createState() => _CompanionOrLivingCoreState();
}

class _CompanionOrLivingCoreState extends State<CompanionOrLivingCore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick;

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(CompanionOrLivingCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presence != widget.presence ||
        oldWidget.breathe != widget.breathe) {
      _sync();
    }
  }

  void _sync() {
    if (!mounted) return;
    final still = !widget.breathe || OraclyQuietMotion.still(context);
    if (still) {
      _tick.stop();
      _tick.value = 0.5;
      return;
    }
    _tick.duration = switch (widget.presence) {
      CompanionOrPresence.thinking => CompanionOrLivingTokens.thinkingOrbit,
      CompanionOrPresence.speaking => CompanionOrLivingTokens.speakingPulse,
      _ => CompanionOrLivingTokens.idleBreath,
    };
    _tick.repeat(reverse: widget.presence != CompanionOrPresence.thinking);
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (OraclyQuietMotion.still(context) || !widget.breathe) {
      return _disk(0.5);
    }
    return AnimatedBuilder(
      animation: _tick,
      builder: (_, _) => _disk(_tick.value),
    );
  }

  Widget _disk(double t) {
    final glow = switch (widget.presence) {
      CompanionOrPresence.thinking => 0.55 + t * 0.35,
      CompanionOrPresence.speaking => 0.5 + t * 0.4,
      _ => 0.35 + t * 0.45,
    };
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: CompanionOrLivingCorePainter(
            phase: t,
            glow: glow,
            compact: widget.compact,
          ),
        ),
      ),
    );
  }
}
