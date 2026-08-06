/// OR-1050+ — Cinematic card reveal orchestrator.
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'card_reveal_spread.dart';
import 'reveal_ambience_layer.dart';
import 'reveal_background.dart';
import 'reveal_flip_card.dart';
import 'reveal_result_panel.dart';
import 'reveal_sound_callbacks.dart';
import 'reveal_timeline.dart';
import '../../theme/tarot_emotional_rhythm.dart';

class CardRevealExperience extends StatefulWidget {
  const CardRevealExperience({
    super.key,
    required this.data,
    required this.onContinue,
    this.soundCallbacks = RevealSoundCallbacks.silent,
  });

  final RevealCardData data;
  final VoidCallback onContinue;
  final RevealSoundCallbacks soundCallbacks;

  @override
  State<CardRevealExperience> createState() => _CardRevealExperienceState();
}

class _CardRevealExperienceState extends State<CardRevealExperience>
    with SingleTickerProviderStateMixin {
  late final AnimationController _master;
  late final RevealSoundCallbackTracker _soundTracker;
  bool _hapticFlip = false;

  @override
  void initState() {
    super.initState();
    _soundTracker = RevealSoundCallbackTracker(widget.soundCallbacks);
    _master = AnimationController(
      vsync: this,
      duration: RevealTimeline.totalDuration,
    )..forward();
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  void _maybeFlipHaptic(double t) {
    if (!_hapticFlip && t >= RevealTimeline.flipStart + 0.06) {
      _hapticFlip = true;
      HapticFeedback.lightImpact();
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
        _soundTracker.tick(t);
        _maybeFlipHaptic(t);

        final zoom = RevealTimeline.cameraZoom(t);
        final floatY =
            RevealTimeline.floatUp(t) + RevealTimeline.floatIdle(t);
        final fog = RevealTimeline.fogRichness(t);
        final particleSpeed = RevealTimeline.particleSpeed(t);
        final glow = RevealTimeline.glowBehind(t);
        final stillness = RevealTimeline.anticipationStillness(t);
        final focus = RevealTimeline.orbFocus(t);
        final deepen = RevealTimeline.ambientDeepen(t);
        final inheritedStillness = (stillness + 0.18 * (1 - t.clamp(0.0, 0.10) / 0.10))
            .clamp(0.0, 1.0);
        final flipPeak = TarotEmotionalRhythm.peakPulse(
          t,
          centre: RevealTimeline.flipEnd,
          width: 0.09,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: RevealBackground(
                darken: RevealTimeline.darken(t),
                stillness: stillness,
                ambientDeepen: deepen,
              ),
            ),
            if (inheritedStillness > 0.04)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(
                      alpha: inheritedStillness * 0.20 + flipPeak * 0.04,
                    ),
                  ),
                ),
              ),
            if (deepen > 0.02)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: deepen * 0.10),
                  ),
                ),
              ),
            Center(
              child: Transform.translate(
                offset: Offset(0, floatY),
                child: Transform.scale(
                  scale: zoom,
                  child: RepaintBoundary(
                    child: SizedBox(
                      width: 360,
                      height: 360,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: RevealAmbienceLayer(
                              progress: t,
                              fogIntensity: fog,
                              particleSpeed: particleSpeed,
                              glowIntensity: glow,
                              particlePhase: t * pi * 2 * RevealTimeline.particleDrift(t),
                              stillness: inheritedStillness,
                              orbFocus: focus,
                            ),
                          ),
                          RevealFlipCard(
                            data: widget.data,
                            flipRotation: RevealTimeline.flipRotation(t),
                            tilt3D: RevealTimeline.tilt3D(t),
                            perspectiveTiltY:
                                RevealTimeline.perspectiveTiltY(t),
                            borderEnergy: RevealTimeline.borderEnergy(t),
                            landScale: RevealTimeline.landScale(t),
                            shadowDepth: RevealTimeline.shadowDepth(t),
                            goldOpacity: RevealTimeline.frontGoldOpacity(t),
                            artOpacity: RevealTimeline.frontArtOpacity(t),
                            particlePhase: t * pi * 2 * RevealTimeline.particleDrift(t),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                minimum: const EdgeInsets.only(bottom: 16),
                child: RevealResultPanel(
                  data: widget.data,
                  nameOpacity: RevealTimeline.nameOpacity(t),
                  subtitleOpacity: RevealTimeline.subtitleOpacity(t),
                  badgeOpacity: RevealTimeline.badgeOpacity(t),
                  buttonOpacity: RevealTimeline.buttonOpacity(t),
                  buttonSlide: RevealTimeline.buttonSlide(t),
                  onContinue: widget.onContinue,
                ),
              ),
            ),
          ],
        );
      },
      ),
    );
  }
}
