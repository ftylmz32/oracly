/// EPIC-025 — Tarot screen transition animations (delegates to immersive system).
library;

import 'package:flutter/material.dart';

import '../../../../core/feature_flags/feature_flag_rollback.dart';
import '../../../../core/feature_flags/feature_flag_surface.dart';
import '../../../../core/navigation/immersive/chamber_transition_personality.dart';
import '../../../../core/navigation/immersive/immersive_transition.dart';
import '../../../../core/navigation/oracly_page_transitions.dart';
import '../../motion/tarot_cinematic_motion.dart';
import '../../theme/tarot_tokens.dart';

/// Premium ritual page transition — fade, slide, subtle scale.
class TarotRitualTransition extends StatelessWidget {
  const TarotRitualTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ImmersivePageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      mode: ImmersiveTransitionMode.enter,
      child: child,
    );
  }
}

/// Depth handoff — inherits mood from the previous ritual stage.
class TarotRitualDepthHandoff extends StatelessWidget {
  const TarotRitualDepthHandoff({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    this.scaleBegin = TarotTokens.handoffScaleBegin,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;
  final double scaleBegin;

  @override
  Widget build(BuildContext context) {
    return ImmersivePageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      mode: ImmersiveTransitionMode.depth,
      scaleBegin: scaleBegin,
      child: child,
    );
  }
}

/// Builds a route with the standard tarot transition.
Route<T> tarotRitualRoute<T>({
  required Widget page,
  RouteSettings? settings,
}) {
  if (!FeatureFlagRollback.useExperimental(FeatureFlagSurface.tarotAnimation)) {
    return OraclyPageTransitions.fade<T>(page: page, settings: settings);
  }
  return OraclyPageTransitions.chamber<T>(
    personality: ChamberTransitionPersonality.tarot,
    page: page,
    settings: settings,
  );
}

/// Shared depth handoff for selection → reveal → reading continuity.
Route<T> tarotRitualDepthHandoffRoute<T>({
  required Widget page,
  RouteSettings? settings,
  Duration? duration,
  double scaleBegin = TarotTokens.handoffScaleBegin,
}) {
  if (!FeatureFlagRollback.useExperimental(FeatureFlagSurface.tarotAnimation)) {
    return OraclyPageTransitions.fade<T>(page: page, settings: settings);
  }
  return OraclyPageTransitions.depth<T>(
    page: page,
    settings: settings,
    scaleBegin: scaleBegin,
    duration: duration ?? TarotTokens.ritualHandoff,
    reverseDuration: TarotCinematicMotion.backNav,
  );
}
