/// OR-403 / OR-408 / OR-409 — Scroll-linked sanctuary immersion for Tarot Home.
library;

import 'package:flutter/material.dart';

import 'oracly_sacred_identity.dart';
import 'tarot_home_progressive_discovery.dart';
import 'tarot_home_sanctuary_architecture.dart';

export 'tarot_home_progressive_discovery.dart'
    show TarotHomeDepthSection, TarotHomeScrollScope;

typedef TarotHomeScrollBuilder = Widget Function(
  BuildContext context,
  double scrollOffset,
  double ambientPhase,
);

/// Wraps home scroll content with parallax depth and endless chamber atmosphere.
class TarotHomeCinematicScroll extends StatefulWidget {
  const TarotHomeCinematicScroll({
    super.key,
    required this.builder,
  });

  final TarotHomeScrollBuilder builder;

  @override
  State<TarotHomeCinematicScroll> createState() =>
      _TarotHomeCinematicScrollState();
}

class _TarotHomeCinematicScrollState extends State<TarotHomeCinematicScroll>
    with SingleTickerProviderStateMixin {
  final ScrollController _controller = ScrollController();
  late final AnimationController _ambient;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: OraclyMotion.ambient,
    )..repeat();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final next = _controller.offset;
    if ((next - _scrollOffset).abs() < 1.5) return;
    setState(() => _scrollOffset = next);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _ambient.value;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SingleChildScrollView(
          controller: _controller,
          physics: const ClampingScrollPhysics(),
          child: TarotHomeScrollScope(
            scrollOffset: _scrollOffset,
            ambientPhase: phase,
            child: widget.builder(context, _scrollOffset, phase),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) {
                return CustomPaint(
                  painter: OraclyArchitecturalSilhouettesPainter(
                    phase: phase,
                    scrollOffset: _scrollOffset,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: OraclySacredFloorPatternPainter(
                phase: phase,
                scrollOffset: _scrollOffset,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) {
                return CustomPaint(
                  painter: OraclyOrbLightShaftPainter(
                    phase: phase,
                    scrollOffset: _scrollOffset,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: OraclyScrollChamberVeilPainter(
                scrollOffset: _scrollOffset,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
