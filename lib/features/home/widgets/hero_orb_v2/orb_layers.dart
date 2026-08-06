/// OR-046 — Reference-only layer orchestrator.
library;

import 'layers/orb_layer_core.dart';
import 'layers/orb_layer_fog.dart';
import 'layers/orb_layer_fresnel.dart';
import 'layers/orb_layer_glass.dart';
import 'layers/orb_layer_lattice.dart';
import 'layers/orb_layer_reflections.dart';
import 'layers/orb_layer_thickness.dart';
import 'orb_constants.dart';

/// Paint order: silhouette → volume → lighting (reference image only).
abstract final class OrbV2Layers {
  OrbV2Layers._();

  static void paintAll(OrbV2PaintContext ctx) {
    OrbV2LayerGlass.paint(ctx);
    OrbV2LayerFog.paint(ctx);
    OrbV2LayerCore.paint(ctx);
    OrbV2LayerLattice.paint(ctx);
    OrbV2LayerThickness.paint(ctx);
    OrbV2LayerFresnel.paint(ctx);
    OrbV2LayerReflections.paint(ctx);
  }
}
