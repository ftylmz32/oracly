/// OR-1120 / EPIC-025 — Unified immersive page transition builders.
library;

import 'package:flutter/material.dart';

import 'immersive/chamber_transition_personality.dart';
import 'immersive/immersive_motion.dart';
import 'immersive/immersive_transition.dart';

abstract final class OraclyPageTransitions {
  OraclyPageTransitions._();

  static Route<T> _route<T>({
    required Widget page,
    RouteSettings? settings,
    ImmersiveTransitionMode mode = ImmersiveTransitionMode.enter,
    Duration? duration,
    Duration? reverseDuration,
    double? scaleBegin,
    double? translateBeginPx,
    bool fullscreenDialog = false,
    bool opaque = true,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      opaque: opaque,
      transitionDuration: duration ?? ImmersiveMotion.pageEnter,
      reverseTransitionDuration: reverseDuration ?? ImmersiveMotion.pageExit,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        return ImmersivePageTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          mode: mode,
          scaleBegin: scaleBegin,
          translateBeginPx: translateBeginPx,
          child: child,
        );
      },
    );
  }

  /// Feature-shaped chamber enter — fade, soft scale, soft vertical lift.
  static Route<T> chamber<T>({
    required Widget page,
    required ChamberTransitionPersonality personality,
    RouteSettings? settings,
  }) {
    final tokens = ChamberTransitionTokens.of(personality);
    return _route(
      page: page,
      settings: settings,
      mode: tokens.mode,
      duration: tokens.enter,
      reverseDuration: tokens.exit,
      scaleBegin: tokens.scaleBegin,
      translateBeginPx: tokens.translatePx,
    );
  }

  /// Default immersive enter — fade, scale 0.985→1, translate 18 px.
  static Route<T> enter<T>({
    required Widget page,
    RouteSettings? settings,
  }) =>
      chamber(
        page: page,
        settings: settings,
        personality: ChamberTransitionPersonality.chamber,
      );

  /// Soft fade — splash, history, quiet surfaces.
  static Route<T> fade<T>({
    required Widget page,
    RouteSettings? settings,
    Duration? duration,
    Duration? reverseDuration,
  }) =>
      _route(
        page: page,
        settings: settings,
        mode: ImmersiveTransitionMode.fade,
        duration: duration,
        reverseDuration: reverseDuration,
      );

  /// Vertical slide emphasis — settings, about, privacy.
  static Route<T> slideUp<T>({
    required Widget page,
    RouteSettings? settings,
  }) =>
      _route(
        page: page,
        settings: settings,
        mode: ImmersiveTransitionMode.slide,
      );

  /// Depth handoff — tarot ritual continuity.
  static Route<T> depth<T>({
    required Widget page,
    RouteSettings? settings,
    double scaleBegin = 0.972,
    Duration? duration,
    Duration? reverseDuration,
  }) =>
      _route(
        page: page,
        settings: settings,
        mode: ImmersiveTransitionMode.depth,
        scaleBegin: scaleBegin,
        duration: duration ?? const Duration(milliseconds: 560),
        reverseDuration: reverseDuration,
      );

  /// Light wash enter — premium surfaces.
  static Route<T> light<T>({
    required Widget page,
    RouteSettings? settings,
  }) =>
      _route(
        page: page,
        settings: settings,
        mode: ImmersiveTransitionMode.light,
        duration: const Duration(milliseconds: 480),
      );

  /// Backward-compatible alias — maps to [enter].
  static Route<T> sharedAxis<T>({
    required Widget page,
    RouteSettings? settings,
  }) =>
      enter(page: page, settings: settings);
}
