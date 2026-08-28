/// Transform math for [CardFlightActor] flight timeline.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../gestures/ritual_draw_gesture.dart';
import 'card_flight_phase.dart';

abstract final class CardFlightMath {
  CardFlightMath._();

  static const liftPx = 8.0;
  static const maxTiltRad = 8 * math.pi / 180;

  static CardFlightPhase phaseForProgress(double t) {
    if (t < 0.18) return CardFlightPhase.extracting;
    if (t < 0.42) return CardFlightPhase.centering;
    if (t < 0.72) return CardFlightPhase.flipping;
    if (t < 1.0) return CardFlightPhase.placing;
    return CardFlightPhase.placed;
  }

  static Offset flightOffset({
    required Offset drag,
    required CardFlightPhase phase,
    required double t,
    required Offset? placeTarget,
  }) {
    final lift = phase == CardFlightPhase.dragging ||
            phase == CardFlightPhase.committed ||
            drag.dy < -1
        ? liftPx
        : 0.0;
    final base = Offset(drag.dx, drag.dy - lift);
    if (phase.index < CardFlightPhase.extracting.index) return base;
    final extract = Curves.easeOutCubic.transform((t / 0.28).clamp(0.0, 1.0));
    final center =
        Curves.easeInOut.transform(((t - 0.18) / 0.28).clamp(0.0, 1.0));
    final placeT =
        Curves.easeInOut.transform(((t - 0.72) / 0.28).clamp(0.0, 1.0));
    var o = Offset(base.dx * (1 - center), base.dy);
    o += Offset(0, -120 * extract);
    o = Offset.lerp(o, const Offset(0, -36), center)!;
    if (placeTarget != null && placeT > 0) {
      o = Offset.lerp(o, placeTarget, placeT)!;
    }
    return o;
  }

  static double flipProgress(double t) =>
      Curves.easeInOut.transform(((t - 0.42) / 0.30).clamp(0.0, 1.0));

  static double tilt(Offset drag, CardFlightPhase phase) {
    if (phase.index >= CardFlightPhase.extracting.index) return 0;
    return (drag.dx / 120).clamp(-1.0, 1.0) * maxTiltRad;
  }

  static double dragProgress(Offset drag) =>
      (-drag.dy / RitualDrawThreshold.commitPx).clamp(0.0, 1.2);
}
