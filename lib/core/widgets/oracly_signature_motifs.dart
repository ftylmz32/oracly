/// OR-433 — ORACLY signature micro-details: recurring OL motifs app-wide.
library;

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/oracly_brand_signature.dart';

/// Vesica compass divider — OL-7 inspired centre accent.
class OraclySignatureDivider extends StatelessWidget {
  const OraclySignatureDivider({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact ? AppSpacing.sm : AppSpacing.md,
      ),
      child: SizedBox(
        height: compact ? 10 : 12,
        width: double.infinity,
        child: CustomPaint(painter: OraclySignatureDividerPainter()),
      ),
    );
  }
}

class OraclySignatureDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final cx = size.width / 2;

    final line = Paint()
      ..strokeWidth = 0.4
      ..color = OraclySignaturePalette.goldHairline(
        OraclySignatureMotifs.dividerLineAlpha,
      );
    canvas.drawLine(Offset(0, cy), Offset(cx - 22, cy), line);
    canvas.drawLine(Offset(cx + 22, cy), Offset(size.width, cy), line);

    final vesica = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4
      ..color = OraclySignaturePalette.goldEngrave(OraclySignatureMotifs.vesicaAlpha);
    canvas.drawCircle(Offset(cx - 4.5, cy), 3.5, vesica);
    canvas.drawCircle(Offset(cx + 4.5, cy), 3.5, vesica);

    final tri = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35
      ..color =
          OraclySignaturePalette.goldEngrave(OraclySignatureMotifs.vesicaTriadAlpha);
    final triPath = Path()
      ..moveTo(cx, cy - 3.5)
      ..lineTo(cx - 3, cy + 2)
      ..lineTo(cx + 3, cy + 2)
      ..close();
    canvas.drawPath(triPath, tri);

    canvas.drawCircle(
      Offset(cx, cy + 0.5),
      0.9,
      Paint()
        ..color = OraclySignaturePalette.champagne.withValues(
          alpha: OraclySignatureMotifs.anchorNodeAlpha + 0.06,
        ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Handcrafted corner ornaments — meridian tick + anchor node (OL-1 / OL-6).
class OraclySignatureCornerOrnaments extends StatelessWidget {
  const OraclySignatureCornerOrnaments({
    super.key,
    this.inset = 10,
    this.size = 16,
  });

  final double inset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: inset,
              left: inset,
              child: _Corner(flipX: false, flipY: false, size: size),
            ),
            Positioned(
              top: inset,
              right: inset,
              child: _Corner(flipX: true, flipY: false, size: size),
            ),
            Positioned(
              bottom: inset,
              left: inset,
              child: _Corner(flipX: false, flipY: true, size: size),
            ),
            Positioned(
              bottom: inset,
              right: inset,
              child: _Corner(flipX: true, flipY: true, size: size),
            ),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({
    required this.flipX,
    required this.flipY,
    required this.size,
  });

  final bool flipX;
  final bool flipY;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: flipX,
      flipY: flipY,
      child: CustomPaint(
        painter: OraclySignatureCornerPainter(),
        size: Size(size, size),
      ),
    );
  }
}

class OraclySignatureCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..strokeWidth = 0.45
      ..style = PaintingStyle.stroke
      ..color = OraclySignaturePalette.goldEngrave(
        OraclySignatureMotifs.cornerMeridianAlpha,
      );
    canvas.drawLine(Offset.zero, Offset(size.width * 0.88, 0), gold);
    canvas.drawLine(Offset.zero, Offset(0, size.height * 0.88), gold);

    final tri = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3
      ..color =
          OraclySignaturePalette.goldEngrave(OraclySignatureMotifs.cornerTriadAlpha);
    canvas.drawLine(
      Offset(size.width * 0.42, size.height * 0.42),
      Offset(size.width * 0.62, size.height * 0.22),
      tri,
    );

    canvas.drawCircle(
      Offset(size.width * 0.58, size.height * 0.58),
      0.9,
      Paint()
        ..color = OraclySignaturePalette.champagne.withValues(
          alpha: OraclySignatureMotifs.anchorNodeAlpha,
        ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle celestial framing arc — top edge only, never dominant.
class OraclySignatureCelestialArc extends StatelessWidget {
  const OraclySignatureCelestialArc({
    super.key,
    this.width = 120,
    this.height = 28,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CelestialArcPainter(),
        size: Size(width, height),
      ),
    );
  }
}

class _CelestialArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35
      ..color = OraclySignaturePalette.goldHairline(
        OraclySignatureMotifs.dividerLineAlpha * 0.85,
      );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.85),
        width: size.width * 0.72,
        height: size.height * 1.6,
      ),
      3.35,
      2.2,
      false,
      arc,
    );

    canvas.drawCircle(
      Offset(cx, size.height * 0.42),
      0.7,
      Paint()
        ..color = OraclySignaturePalette.champagne.withValues(
          alpha: OraclySignatureMotifs.anchorNodeAlpha * 0.75,
        ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Quiet crystal facet sheen — overlays glass without layout impact.
class OraclySignatureFacetSheen extends StatelessWidget {
  const OraclySignatureFacetSheen({
    super.key,
    this.intensity = 1.0,
    this.borderRadius,
  });

  final double intensity;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: OraclySignatureReflection.facetSheen(intensity: intensity),
          ),
        ),
      ),
    );
  }
}

/// Wraps premium surfaces with signature corners and optional top arc.
class OraclySignatureMicroFrame extends StatelessWidget {
  const OraclySignatureMicroFrame({
    super.key,
    required this.child,
    this.showCorners = true,
    this.showTopArc = false,
    this.showFacetSheen = true,
    this.cornerInset = 10,
    this.cornerSize = 14,
    this.opacity = 1.0,
    this.borderRadius,
  });

  final Widget child;
  final bool showCorners;
  final bool showTopArc;
  final bool showFacetSheen;
  final double cornerInset;
  final double cornerSize;
  final double opacity;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        child,
        if (showFacetSheen)
          OraclySignatureFacetSheen(
            intensity: opacity,
            borderRadius: borderRadius,
          ),
        if (showCorners)
          Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: OraclySignatureCornerOrnaments(
              inset: cornerInset,
              size: cornerSize,
            ),
          ),
        if (showTopArc)
          Align(
            alignment: Alignment.topCenter,
            child: Opacity(
              opacity: (opacity * 0.72).clamp(0.0, 1.0),
              child: const Padding(
                padding: EdgeInsets.only(top: 6),
                child: OraclySignatureCelestialArc(),
              ),
            ),
          ),
      ],
    );
  }
}
