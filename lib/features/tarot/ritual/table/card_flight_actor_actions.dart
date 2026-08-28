/// Commit / snap / reset actions for [CardFlightActorState].
library;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../presentation/widgets/card_reveal/card_reveal_spread.dart';
import '../gestures/ritual_draw_gesture.dart';
import 'card_flight_actor.dart';
import 'card_flight_phase.dart';

mixin CardFlightActorActions on State<CardFlightActor>, TickerProvider {
  AnimationController get spring;
  AnimationController get flight;
  CardFlightPhase get phase;
  set phase(CardFlightPhase value);
  Offset get drag;
  set drag(Offset value);
  RevealCardData? get face;
  set face(RevealCardData? value);
  bool get drawFired;
  set drawFired(bool value);

  void snapBack() {
    final start = drag.dy;
    phase = CardFlightPhase.onDeck;
    spring.value = start;
    spring
        .animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 180, damping: 16),
        start,
        0,
        0,
      ),
    )
        .whenComplete(() {
      if (!mounted) return;
      setState(() => drag = Offset.zero);
      widget.onDragVisual?.call(0);
    });
  }

  Future<void> commitAndFly() async {
    if (drawFired) return;
    setState(() => phase = CardFlightPhase.committed);
    HapticFeedback.mediumImpact();
    widget.onDragVisual?.call(1);
    drawFired = true;
    final data = await widget.onRequestDraw();
    if (!mounted) return;
    if (data == null) {
      drawFired = false;
      snapBack();
      return;
    }
    face = data;
    if (widget.reducedMotion) {
      setState(() {
        phase = CardFlightPhase.placed;
        drag = widget.placeTarget ?? const Offset(0, -120);
      });
      widget.onFlightComplete(face!);
      return;
    }
    setState(() => phase = CardFlightPhase.extracting);
    await flight.forward(from: 0);
    if (!mounted) return;
    setState(() => phase = CardFlightPhase.placed);
    widget.onFlightComplete(face!);
  }

  void resetForNextDraw() {
    spring.stop();
    flight
      ..stop()
      ..value = 0;
    setState(() {
      drawFired = false;
      face = null;
      drag = Offset.zero;
      phase = CardFlightPhase.onDeck;
    });
  }

  bool get canDrag =>
      widget.enabled &&
      (phase == CardFlightPhase.onDeck || phase == CardFlightPhase.dragging);

  void onPanStart() {
    widget.onInteracted();
    spring.stop();
    setState(() => phase = CardFlightPhase.dragging);
    HapticFeedback.selectionClick();
  }

  void onPanUpdate(DragUpdateDetails d) {
    setState(() {
      drag += d.delta;
      drag = Offset(
        drag.dx.clamp(-48.0, 48.0),
        drag.dy.clamp(-RitualDrawThreshold.commitPx * 1.4, 24.0),
      );
    });
    widget.onDragVisual?.call((-drag.dy / RitualDrawThreshold.commitPx).clamp(0.0, 1.2));
  }

  Future<void> onPanEnd() async {
    if (-drag.dy >= RitualDrawThreshold.commitPx) {
      await commitAndFly();
    } else {
      setState(() => phase = CardFlightPhase.onDeck);
      snapBack();
    }
  }
}
