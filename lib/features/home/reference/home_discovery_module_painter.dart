/// Discovery tile painter — chamber gradients and motif dispatch.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/oracly_brand_signature.dart';
import 'home_discovery_module_motifs.dart';
import 'home_discovery_soulmate_motif.dart';
import 'home_module_visual.dart';

class DiscoveryModulePainter extends CustomPainter {
  const DiscoveryModulePainter(this.visual);

  final HomeModuleVisual visual;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = _bg(visual).createShader(rect));
    _vignette(canvas, size);
    _stars(canvas, size, visual == HomeModuleVisual.starMap ? 40 : 20);
    switch (visual) {
      case HomeModuleVisual.coffee:
        paintCoffeeMotif(canvas, size);
      case HomeModuleVisual.palm:
        paintPalmMotif(canvas, size);
      case HomeModuleVisual.astrology:
        paintAstrologyMotif(canvas, size);
      case HomeModuleVisual.starMap:
        paintStarMapMotif(canvas, size);
      case HomeModuleVisual.soulMate:
        paintSoulMateMotif(canvas, size);
      case HomeModuleVisual.tarot:
        break;
      case HomeModuleVisual.dream:
        break;
    }
  }

  void _vignette(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.15),
          radius: 1.15,
          colors: [Colors.transparent, const Color(0x66000000)],
          stops: const [0.45, 1],
        ).createShader(Offset.zero & size),
    );
  }

  LinearGradient _bg(HomeModuleVisual v) {
    return switch (v) {
      HomeModuleVisual.coffee => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A1C0C), Color(0xFF1E1008), Color(0xFF0E0804)],
        ),
      HomeModuleVisual.palm => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1C1230), Color(0xFF120A22), OraclySignaturePalette.obsidian],
        ),
      HomeModuleVisual.astrology => const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF221448), Color(0xFF140A2A), Color(0xFF080610)],
        ),
      HomeModuleVisual.starMap => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF06040E), Color(0xFF12081E), Color(0xFF04030A)],
        ),
      HomeModuleVisual.soulMate => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0E2C), Color(0xFF2A1840), Color(0xFF0A0614)],
        ),
      HomeModuleVisual.tarot => const LinearGradient(
          colors: [OraclySignaturePalette.obsidian, OraclySignaturePalette.obsidian],
        ),
      HomeModuleVisual.dream => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14102A), Color(0xFF0A0618), Color(0xFF05030C)],
        ),
    };
  }

  void _stars(Canvas canvas, Size size, int count) {
    final rnd = math.Random(visual.index + 11);
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.7),
        rnd.nextDouble() * 1.15 + 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.07 + rnd.nextDouble() * 0.16),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DiscoveryModulePainter oldDelegate) =>
      oldDelegate.visual != visual;
}
