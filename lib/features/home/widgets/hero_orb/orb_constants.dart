/// OR-031B — Hero orb layout and motion tokens.
library;

/// Proportional geometry for the premium centerpiece hero orb.
abstract final class OrbLayout {
  OrbLayout._();

  /// Visual scale boost — ~55% larger without changing Home layout props.
  static const double sizeMultiplier = 1.55;

  static double renderSize(double size) => size * sizeMultiplier;

  /// Crystal shell fills most of the render box.
  static double sphereDiameter(double size) => renderSize(size) * 0.90;

  static double sphereInset(double size) =>
      (renderSize(size) - sphereDiameter(size)) / 2;

  /// Bright golden energy core — prominent centerpiece.
  static double coreOuter(double size) => sphereDiameter(size) * 0.48;

  static double coreInner(double size) => sphereDiameter(size) * 0.34;

  static double coreNucleus(double size) => sphereDiameter(size) * 0.16;

  /// OR mark — large, sharp, bright.
  static double logoFontSize(double size) => sphereDiameter(size) * 0.19;

  static double logoTracking(double size) => renderSize(size) * 0.028;

  /// Thick outer purple ring inset from sphere edge.
  static double outerRingWidth(double size) => sphereDiameter(size) * 0.060;

  static const Duration breathe = Duration(milliseconds: 7000);

  static const double breatheScaleMin = 0.985;
  static const double breatheScaleMax = 1.015;
}

abstract final class OrbMotion {
  OrbMotion._();

  static const Duration coreBreathe = OrbLayout.breathe;
}
