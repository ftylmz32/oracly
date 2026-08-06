/// OR-999 — Hero Orb scene (Home v1.0 FROZEN).
library;

import 'package:flutter/material.dart';

import '../../theme/home_focus.dart';
import '../../theme/home_presence.dart';
import 'orb_animation.dart';
import 'orb_cache.dart';
import 'orb_constants.dart';
import 'orb_renderer.dart';

/// Sized, cached scene root — breathing + float on shell; overlays repaint independently.
class OrbScene extends StatefulWidget {
  const OrbScene({super.key, required this.layoutSize});

  final double layoutSize;

  @override
  State<OrbScene> createState() => _OrbSceneState();
}

class _OrbSceneState extends State<OrbScene> with TickerProviderStateMixin {
  late final OrbAnimationBundle _motion;
  late double _canvasSize;
  late Alignment _pivot;

  @override
  void initState() {
    super.initState();
    _motion = OrbAnimationBundle(
      vsync: this,
      syncPhase: HomePresenceRhythm.clockPhase(),
    );
    _syncLayoutMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) OrbCache.precache(context);
    });
  }

  @override
  void didUpdateWidget(covariant OrbScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layoutSize != widget.layoutSize) {
      _syncLayoutMetrics();
    }
  }

  void _syncLayoutMetrics() {
    _canvasSize = OrbConstants.renderSize(widget.layoutSize);
    _pivot = Alignment(
      (OrbConstants.sphereCenterNorm.dx - 0.5) * 2,
      (OrbConstants.sphereCenterNorm.dy - 0.5) * 2,
    );
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = HomeFocusScope.maybeOf(context);
    final motionScale = scope?.motionFor(HomeFocusZone.orb) ?? 1.0;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _motion.transformMotion,
        builder: (context, child) {
          final breatheDelta = _motion.breatheScale - 1.0;
          return Transform.translate(
            offset: Offset(0, _motion.floatDy * motionScale),
            child: Transform.scale(
              scale: 1.0 + breatheDelta * motionScale,
              alignment: _pivot,
              child: child,
            ),
          );
        },
        child: OrbRenderer(
          layoutSize: widget.layoutSize,
          canvasSize: _canvasSize,
          motion: _motion,
          overlayIntensity: motionScale,
          rewardBoost: scope?.orbRewardBoost ?? 1.0,
        ),
      ),
    );
  }
}
