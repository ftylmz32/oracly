/// EPIC-005 — Living Universe ambient layer — rare events, zero layout impact.
library;

import 'package:flutter/material.dart';

import 'oracly_living_event.dart';
import 'oracly_universe_painters.dart';
import 'oracly_universe_state.dart';

export 'oracly_universe_scope.dart';
export 'oracly_universe_ticker.dart';

/// Overlays rare ambient moments on top of existing chamber backgrounds.
///
/// Uses at most one short [AnimationController] when a timed event plays.
/// Constellation drift reuses wall-clock phase — no extra loop.
class OraclyUniverseLayer extends StatefulWidget {
  const OraclyUniverseLayer({
    super.key,
    this.state,
    this.masterPhase,
  });

  final OraclyUniverseState? state;
  final double? masterPhase;

  @override
  State<OraclyUniverseLayer> createState() => _OraclyUniverseLayerState();
}

class _OraclyUniverseLayerState extends State<OraclyUniverseLayer>
    with SingleTickerProviderStateMixin {
  AnimationController? _eventController;
  OraclyLivingEvent? _event;

  @override
  void initState() {
    super.initState();
    _bindEvent(widget.state ?? OraclyUniverseState.current());
  }

  @override
  void didUpdateWidget(covariant OraclyUniverseLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.state ?? OraclyUniverseState.current();
    if (next.livingEvent?.seed != _event?.seed) {
      _disposeEventController();
      _bindEvent(next);
    }
  }

  void _bindEvent(OraclyUniverseState universe) {
    final event = universe.livingEvent;
    if (event == null) return;

    _event = event;
    if (event.kind == OraclyLivingEventKind.shiftingConstellation) return;

    final duration = switch (event.kind) {
      OraclyLivingEventKind.shootingStar => const Duration(milliseconds: 2800),
      OraclyLivingEventKind.distantGlow => const Duration(milliseconds: 9200),
      OraclyLivingEventKind.goldenReflection =>
        const Duration(milliseconds: 4800),
      OraclyLivingEventKind.shiftingConstellation => Duration.zero,
    };

    _eventController = AnimationController(vsync: this, duration: duration)
      ..forward();
  }

  void _disposeEventController() {
    _eventController?.dispose();
    _eventController = null;
    _event = null;
  }

  @override
  void dispose() {
    _disposeEventController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    if (event == null) return const SizedBox.shrink();

    final constellationPhase = widget.masterPhase ??
        ((DateTime.now().millisecondsSinceEpoch % 53000) / 53000.0);
    final controller = _eventController;

    Widget paint(double progress) => RepaintBoundary(
          child: CustomPaint(
            painter: OraclyLivingEventPainter(
              event: event,
              progress: progress,
              constellationPhase: constellationPhase,
            ),
            child: const SizedBox.expand(),
          ),
        );

    if (controller == null) return paint(0);
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => paint(controller.value),
    );
  }
}
