/// Chamber enter personalities — same universe, different room feel.
library;

import 'immersive_motion.dart';
import 'immersive_transition.dart';

/// Feature-shaped door into a chamber. Never a platform page flicker.
enum ChamberTransitionPersonality {
  /// Default soft room enter.
  chamber,

  /// Slightly slower / ceremonial.
  tarot,

  /// Quiet / immediate.
  orPresence,

  /// Warm / soft.
  coffee,

  /// Celestial / fluid.
  astrology,

  /// Cinematic / gentle.
  soulMate,

  /// Quiet celestial archive.
  yildizname,
}

/// Timing + spatial tokens for [ChamberTransitionPersonality].
class ChamberTransitionTokens {
  const ChamberTransitionTokens({
    required this.enter,
    required this.exit,
    required this.scaleBegin,
    required this.translatePx,
    this.slideFraction = 0.018,
    this.mode = ImmersiveTransitionMode.enter,
  });

  final Duration enter;
  final Duration exit;
  final double scaleBegin;
  final double translatePx;
  final double slideFraction;
  final ImmersiveTransitionMode mode;

  static ChamberTransitionTokens of(ChamberTransitionPersonality personality) {
    return switch (personality) {
      ChamberTransitionPersonality.tarot => const ChamberTransitionTokens(
          enter: Duration(milliseconds: 580),
          exit: Duration(milliseconds: 380),
          scaleBegin: 0.978,
          translatePx: 12,
          slideFraction: 0.014,
          mode: ImmersiveTransitionMode.depth,
        ),
      ChamberTransitionPersonality.orPresence => const ChamberTransitionTokens(
          enter: Duration(milliseconds: 320),
          exit: Duration(milliseconds: 260),
          scaleBegin: 0.994,
          translatePx: 6,
          slideFraction: 0.008,
          mode: ImmersiveTransitionMode.fade,
        ),
      ChamberTransitionPersonality.coffee => const ChamberTransitionTokens(
          enter: Duration(milliseconds: 460),
          exit: Duration(milliseconds: 320),
          scaleBegin: 0.990,
          translatePx: 12,
          slideFraction: 0.014,
        ),
      ChamberTransitionPersonality.astrology => const ChamberTransitionTokens(
          enter: Duration(milliseconds: 500),
          exit: Duration(milliseconds: 340),
          scaleBegin: 0.986,
          translatePx: 14,
          slideFraction: 0.016,
        ),
      ChamberTransitionPersonality.soulMate => const ChamberTransitionTokens(
          enter: Duration(milliseconds: 520),
          exit: Duration(milliseconds: 360),
          scaleBegin: 0.982,
          translatePx: 10,
          slideFraction: 0.012,
          mode: ImmersiveTransitionMode.light,
        ),
      ChamberTransitionPersonality.yildizname => const ChamberTransitionTokens(
          enter: Duration(milliseconds: 500),
          exit: Duration(milliseconds: 340),
          scaleBegin: 0.988,
          translatePx: 12,
          slideFraction: 0.014,
        ),
      ChamberTransitionPersonality.chamber => ChamberTransitionTokens(
          enter: ImmersiveMotion.pageEnter,
          exit: ImmersiveMotion.pageExit,
          scaleBegin: ImmersiveMotion.pageEnterScaleBegin,
          translatePx: ImmersiveMotion.pageEnterTranslatePx,
          slideFraction: 0.018,
        ),
    };
  }
}
