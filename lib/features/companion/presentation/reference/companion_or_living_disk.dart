/// Living OR disk — one ticker: idle breath / speaking pulse / thinking orbit.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'companion_or_atmosphere.dart';
import 'companion_or_living_tokens.dart';
import 'companion_or_presence.dart';
import 'companion_or_static_disk.dart';

class CompanionOrLivingDisk extends StatefulWidget {
  const CompanionOrLivingDisk({
    super.key,
    required this.size,
    required this.atmosphere,
    required this.presence,
  });

  final double size;
  final CompanionOrAtmosphere atmosphere;
  final CompanionOrPresence presence;

  @override
  State<CompanionOrLivingDisk> createState() => _CompanionOrLivingDiskState();
}

class _CompanionOrLivingDiskState extends State<CompanionOrLivingDisk>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick;

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(vsync: this);
    _sync();
  }

  @override
  void didUpdateWidget(CompanionOrLivingDisk oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.atmosphere.breath != widget.atmosphere.breath ||
        oldWidget.presence != widget.presence) {
      _sync();
    }
  }

  void _sync() {
    final duration = switch (widget.presence) {
      CompanionOrPresence.speaking => CompanionOrLivingTokens.speakingPulse,
      CompanionOrPresence.thinking => CompanionOrLivingTokens.thinkingOrbit,
      _ => widget.atmosphere.breath,
    };
    if (duration == Duration.zero) {
      _tick.stop();
      _tick.value = 0.5;
      return;
    }
    _tick.duration = duration;
    _tick.repeat(reverse: widget.presence != CompanionOrPresence.thinking);
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tick,
      builder: (context, _) {
        return CompanionOrStaticDisk(
          size: widget.size,
          atmosphere: widget.atmosphere,
          glow: widget.atmosphere.glowMin +
              widget.atmosphere.glowSpan * _glowPhase(_tick.value),
          presence: widget.presence,
          phase: _tick.value,
        );
      },
    );
  }

  double _glowPhase(double t) {
    if (widget.presence == CompanionOrPresence.speaking) {
      return 0.5 + 0.5 * math.sin(t * math.pi * 2);
    }
    if (widget.presence == CompanionOrPresence.thinking) {
      return 0.55 + 0.45 * ((math.sin(t * math.pi * 2) + 1) * 0.5);
    }
    return t;
  }
}
