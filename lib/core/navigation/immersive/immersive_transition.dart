/// EPIC-025 — Unified page enter / exit transition widget.
library;

import 'package:flutter/material.dart';

import 'immersive_motion.dart';

/// How a route arrives — all modes share the same soft motion language.
enum ImmersiveTransitionMode {
  /// Default: fade + scale + translate (18 px).
  enter,

  /// Fade only — splash, history lists.
  fade,

  /// Stronger vertical slide — sheets-style pushes.
  slide,

  /// Scale handoff — tarot ritual depth continuity.
  depth,

  /// Light wash — subtle brightness on enter.
  light,
}

/// Applies EPIC-025 enter on [animation] and subtle exit on [secondaryAnimation].
class ImmersivePageTransition extends StatelessWidget {
  const ImmersivePageTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    this.mode = ImmersiveTransitionMode.enter,
    this.scaleBegin,
    this.translateBeginPx,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;
  final ImmersiveTransitionMode mode;
  final double? scaleBegin;
  final double? translateBeginPx;

  @override
  Widget build(BuildContext context) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: ImmersiveMotion.pageEnterCurve,
      reverseCurve: ImmersiveMotion.pageExitCurve,
    );
    final exit = CurvedAnimation(
      parent: secondaryAnimation,
      curve: ImmersiveMotion.pageExitCurve,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      builder: (context, child) {
        final t = enter.value;
        final x = exit.value;

        final opacity = _opacity(t, x);
        final scale = _scale(t, x);
        final dy = _translateY(t, x);

        Widget body = child!;

        if (mode == ImmersiveTransitionMode.light) {
          // Whisper of warmth — never a full-screen flash.
          body = ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.white.withValues(alpha: (1 - t) * 0.035),
              BlendMode.srcOver,
            ),
            child: body,
          );
        }

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              alignment: _alignmentFor(mode),
              child: body,
            ),
          ),
        );
      },
      child: child,
    );
  }

  double _opacity(double t, double x) {
    final enterOpacity = switch (mode) {
      ImmersiveTransitionMode.fade => t,
      _ => t,
    };
    return enterOpacity * (1 - x * ImmersiveMotion.pageExitFadeAmount);
  }

  double _scale(double t, double x) {
    final begin = scaleBegin ??
        switch (mode) {
          ImmersiveTransitionMode.depth => 0.972,
          ImmersiveTransitionMode.slide => 0.992,
          _ => ImmersiveMotion.pageEnterScaleBegin,
        };
    final end = ImmersiveMotion.pageEnterScaleEnd;
    final enterScale = begin + (end - begin) * t;
    return enterScale - x * 0.006;
  }

  double _translateY(double t, double x) {
    final beginPx = translateBeginPx ??
        switch (mode) {
          ImmersiveTransitionMode.slide => 28,
          ImmersiveTransitionMode.depth => 8,
          ImmersiveTransitionMode.fade => 10,
          _ => ImmersiveMotion.pageEnterTranslatePx,
        };
    final enterY = beginPx * (1 - t);
    final exitY = ImmersiveMotion.pageExitTranslatePx * x;
    return enterY + exitY;
  }

  Alignment _alignmentFor(ImmersiveTransitionMode mode) {
    return switch (mode) {
      ImmersiveTransitionMode.depth => Alignment.center,
      _ => Alignment.topCenter,
    };
  }
}

/// Modal / dialog enter — fade + scale from center.
class ImmersiveOverlayTransition extends StatelessWidget {
  const ImmersiveOverlayTransition({
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
      curve: ImmersiveMotion.pageEnterCurve,
      reverseCurve: ImmersiveMotion.pageExitCurve,
    );

    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: ImmersiveMotion.overlayScaleBegin,
          end: 1,
        ).animate(curved),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// Material [PageTransitionsBuilder] wired to [ImmersivePageTransition].
class ImmersivePageTransitionsBuilder extends PageTransitionsBuilder {
  const ImmersivePageTransitionsBuilder({
    this.mode = ImmersiveTransitionMode.enter,
  });

  final ImmersiveTransitionMode mode;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ImmersivePageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      mode: mode,
      child: child,
    );
  }
}
