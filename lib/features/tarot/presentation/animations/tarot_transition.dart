/// OR-1000 / OR-432 — Tarot screen transition animations.
library;

import 'package:flutter/material.dart';

import '../../theme/tarot_tokens.dart';

/// Premium ritual page transition — fade, slide, subtle scale.
class TarotRitualTransition extends StatelessWidget {
  const TarotRitualTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: TarotTokens.revealCurve,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.028),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.988, end: 1).animate(curved),
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
    );
  }
}

/// Depth handoff — inherits mood from the previous ritual stage.
class TarotRitualDepthHandoff extends StatelessWidget {
  const TarotRitualDepthHandoff({
    super.key,
    required this.animation,
    required this.child,
    this.scaleBegin = TarotTokens.handoffScaleBegin,
  });

  final Animation<double> animation;
  final Widget child;
  final double scaleBegin;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: TarotTokens.ritualCurve,
    );
    final scale = Tween<double>(begin: scaleBegin, end: 1.0).animate(fade);
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: scale,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// Builds a [PageRouteBuilder] with the standard tarot transition.
PageRouteBuilder<T> tarotRitualRoute<T>({
  required Widget page,
  RouteSettings? settings,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: TarotTokens.transitionSlow,
    reverseTransitionDuration: TarotTokens.transitionNormal,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return TarotRitualTransition(animation: animation, child: child);
    },
  );
}

/// Shared depth handoff for selection → reveal → reading continuity.
PageRouteBuilder<T> tarotRitualDepthHandoffRoute<T>({
  required Widget page,
  RouteSettings? settings,
  Duration? duration,
  double scaleBegin = TarotTokens.handoffScaleBegin,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: duration ?? TarotTokens.ritualHandoff,
    reverseTransitionDuration: TarotTokens.transitionNormal,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return TarotRitualDepthHandoff(
        animation: animation,
        scaleBegin: scaleBegin,
        child: child,
      );
    },
  );
}
