/// EPIC-005 — Living Universe ambient layer — rare events, zero layout impact.
library;

import 'package:flutter/material.dart';

import 'oracly_living_event.dart';
import 'oracly_universe_painters.dart';
import 'oracly_universe_state.dart';

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
      ..addListener(() {
        if (mounted) setState(() {});
      })
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

    final progress = _eventController?.value ?? 0.0;
    final constellationPhase = widget.masterPhase ??
        ((DateTime.now().millisecondsSinceEpoch % 53000) / 53000.0);

    return RepaintBoundary(
      child: CustomPaint(
        painter: OraclyLivingEventPainter(
          event: event,
          progress: progress,
          constellationPhase: constellationPhase,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Lightweight inherited scope — optional future propagation to tarot chambers.
class OraclyUniverseScope extends InheritedWidget {
  const OraclyUniverseScope({
    super.key,
    required this.state,
    required super.child,
  });

  final OraclyUniverseState state;

  static OraclyUniverseState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<OraclyUniverseScope>();
    assert(scope != null, 'OraclyUniverseScope not found');
    return scope!.state;
  }

  static OraclyUniverseState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OraclyUniverseScope>()?.state;

  @override
  bool updateShouldNotify(covariant OraclyUniverseScope oldWidget) =>
      oldWidget.state.moment.day != state.moment.day ||
      oldWidget.state.moment.hour != state.moment.hour;
}

/// Schedules a once-per-hour universe refresh so ritual transitions stay alive
/// without a perpetual animation loop.
class OraclyUniverseTicker extends StatefulWidget {
  const OraclyUniverseTicker({
    super.key,
    required this.child,
    this.builder,
  });

  final Widget child;
  final Widget Function(BuildContext context, OraclyUniverseState state)?
      builder;

  @override
  State<OraclyUniverseTicker> createState() => _OraclyUniverseTickerState();
}

class _OraclyUniverseTickerState extends State<OraclyUniverseTicker> {
  OraclyUniverseState _state = OraclyUniverseState.current();

  @override
  void initState() {
    super.initState();
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    final delay = nextHour.difference(now);

    Future<void>.delayed(delay, () {
      if (!mounted) return;
      setState(() => _state = OraclyUniverseState.current());
      _scheduleRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return OraclyUniverseScope(
      state: _state,
      child: widget.builder?.call(context, _state) ?? widget.child,
    );
  }
}
