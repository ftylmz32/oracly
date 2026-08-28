/// ONE mounted actor: deck → drag → commit → extract → flip → place.
library;

import 'package:flutter/material.dart';

import '../../presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'card_flight_actor_actions.dart';
import 'card_flight_face.dart';
import 'card_flight_math.dart';
import 'card_flight_phase.dart';

class CardFlightActor extends StatefulWidget {
  const CardFlightActor({
    super.key,
    required this.enabled,
    required this.onRequestDraw,
    required this.onFlightComplete,
    required this.onInteracted,
    this.onDragVisual,
    this.placeTarget,
    this.reducedMotion = false,
  });

  final bool enabled;
  final Future<RevealCardData?> Function() onRequestDraw;
  final ValueChanged<RevealCardData> onFlightComplete;
  final VoidCallback onInteracted;
  final ValueChanged<double>? onDragVisual;
  final Offset? placeTarget;
  final bool reducedMotion;

  @override
  State<CardFlightActor> createState() => CardFlightActorState();
}

class CardFlightActorState extends State<CardFlightActor>
    with TickerProviderStateMixin, CardFlightActorActions {
  late final AnimationController _spring;
  late final AnimationController _flight;
  @override
  CardFlightPhase phase = CardFlightPhase.onDeck;
  @override
  Offset drag = Offset.zero;
  @override
  RevealCardData? face;
  @override
  bool drawFired = false;

  /// Stable identity for continuity tests — never replaced mid-flight.
  late final Object identityToken = Object();

  static const liftPx = CardFlightMath.liftPx;
  static const maxTiltRad = CardFlightMath.maxTiltRad;

  @override
  AnimationController get spring => _spring;
  @override
  AnimationController get flight => _flight;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController.unbounded(vsync: this)..addListener(_onSpring);
    _flight = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(_onFlightTick);
  }

  void _onSpring() {
    if (phase != CardFlightPhase.onDeck) return;
    setState(() => drag = Offset(0, _spring.value));
    widget.onDragVisual?.call(CardFlightMath.dragProgress(drag));
  }

  void _onFlightTick() {
    if (phase.index < CardFlightPhase.extracting.index) return;
    setState(() => phase = CardFlightMath.phaseForProgress(_flight.value));
  }

  @override
  void dispose() {
    _spring.dispose();
    _flight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = CardFlightMath.dragProgress(drag);
    final offset = CardFlightMath.flightOffset(
      drag: drag,
      phase: phase,
      t: _flight.value,
      placeTarget: widget.placeTarget,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: canDrag ? (_) => onPanStart() : null,
      onPanUpdate: canDrag ? onPanUpdate : null,
      onPanEnd: canDrag ? (_) => onPanEnd() : null,
      onPanCancel: canDrag
          ? () {
              setState(() => phase = CardFlightPhase.onDeck);
              snapBack();
            }
          : null,
      child: Transform.translate(
        offset: offset,
        child: Transform.rotate(
          angle: CardFlightMath.tilt(drag, phase),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.35 + 0.25 * progress.clamp(0.0, 1.0),
                  ),
                  blurRadius: 18 + 16 * progress.clamp(0.0, 1.0),
                  offset: Offset(0, 8 + 10 * progress.clamp(0.0, 1.0)),
                ),
              ],
            ),
            child: CardFlightFace(
              flipProgress: CardFlightMath.flipProgress(_flight.value),
              face: face,
            ),
          ),
        ),
      ),
    );
  }
}
