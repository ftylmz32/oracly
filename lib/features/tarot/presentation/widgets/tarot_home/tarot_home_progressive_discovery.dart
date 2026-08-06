/// OR-409 — Progressive discovery: scroll-linked chamber reveals.
library;

import 'dart:math' show cos, pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'oracly_sacred_identity.dart';
import 'tarot_atmosphere.dart';

/// Hand-tuned reveal curve per chamber — slightly different, never identical.
class OraclySectionDiscoveryProfile {
  const OraclySectionDiscoveryProfile({
    required this.revealAnchor,
    required this.revealSpan,
    required this.lead,
    this.lift = 12,
    this.maxBlur = 1.2,
    this.curve = Curves.easeOutCubic,
  });

  final double revealAnchor;
  final double revealSpan;
  final double lead;
  final double lift;
  final double maxBlur;
  final Curve curve;
}

/// Scroll-based discovery math — one focal chamber at a time.
abstract final class OraclyDiscovery {
  OraclyDiscovery._();

  static const _profiles = <OraclySectionDiscoveryProfile>[
    OraclySectionDiscoveryProfile(
      revealAnchor: 0,
      revealSpan: 1,
      lead: 0,
      lift: 0,
      maxBlur: 0,
    ),
    OraclySectionDiscoveryProfile(
      revealAnchor: 280,
      revealSpan: 340,
      lead: 160,
      lift: 14,
      maxBlur: 1.2,
      curve: Curves.easeOutQuart,
    ),
    OraclySectionDiscoveryProfile(
      revealAnchor: 640,
      revealSpan: 310,
      lead: 150,
      lift: 12,
      maxBlur: 1.0,
      curve: Curves.easeOutCubic,
    ),
    OraclySectionDiscoveryProfile(
      revealAnchor: 1000,
      revealSpan: 290,
      lead: 140,
      lift: 13,
      maxBlur: 1.15,
      curve: Curves.easeOutQuart,
    ),
    OraclySectionDiscoveryProfile(
      revealAnchor: 1360,
      revealSpan: 270,
      lead: 130,
      lift: 11,
      maxBlur: 1.0,
      curve: Curves.easeOutCubic,
    ),
  ];

  static OraclySectionDiscoveryProfile profileFor(int index) {
    if (index < 0) return _profiles.first;
    if (index >= _profiles.length) return _profiles.last;
    return _profiles[index];
  }

  static double revealProgress(double scrollOffset, int index) {
    if (index == 0) return 1.0;
    final p = profileFor(index);
    final raw = (scrollOffset - p.revealAnchor + p.lead) / p.revealSpan;
    return p.curve.transform(raw.clamp(0.0, 1.0));
  }

  static int focusedSection(double scrollOffset) {
    if (scrollOffset < 240) return 0;
    if (scrollOffset < 580) return 1;
    if (scrollOffset < 940) return 2;
    if (scrollOffset < 1280) return 3;
    return 4;
  }

  static double focusWeight(int index, double scrollOffset) {
    final active = focusedSection(scrollOffset);
    final dist = (index - active).abs();
    return switch (dist) {
      0 => 1.0,
      1 => 0.74,
      _ => 0.56,
    };
  }

  static double richness(double progress) => 0.66 + progress * 0.34;

  static double composedOpacity(double progress, double focus) {
    final base = 0.22 + progress * 0.78;
    return (base * (0.88 + focus * 0.12)).clamp(0.0, 1.0);
  }
}

/// Propagates discovery richness to crystal surfaces within a chamber.
/// Defined in [oracly_sacred_identity.dart].
/// Micro particles that briefly awaken as a chamber emerges.
class OraclyAwakeningSparkPainter extends CustomPainter {
  const OraclyAwakeningSparkPainter({
    required this.revealProgress,
    required this.phase,
  });

  final double revealProgress;
  final double phase;

  double get _awakening {
    if (revealProgress < 0.12 || revealProgress > 0.82) return 0;
    final t = (revealProgress - 0.12) / 0.7;
    return sin(t * pi) * 0.14;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final strength = _awakening;
    if (strength <= 0) return;

    const seeds = <(double x, double y, double s)>[
      (0.18, 0.22, 0.6),
      (0.82, 0.18, 0.5),
      (0.50, 0.12, 0.7),
      (0.32, 0.38, 0.45),
      (0.68, 0.42, 0.55),
    ];

    for (var i = 0; i < seeds.length; i++) {
      final (x, y, dot) = seeds[i];
      final drift = phase * pi * 2 + i * 1.3;
      final px = size.width * x + cos(drift) * 4;
      final py = size.height * y + sin(drift * 0.9) * 3;

      canvas.drawCircle(
        Offset(px, py),
        dot,
        Paint()
          ..color = OraclySacredPalette.champagne
              .withValues(alpha: strength * (0.6 + i * 0.08)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant OraclyAwakeningSparkPainter old) =>
      old.revealProgress != revealProgress || old.phase != phase;
}

/// Wraps a chamber with scroll-linked progressive discovery.
class TarotHomeProgressiveReveal extends StatelessWidget {
  const TarotHomeProgressiveReveal({
    super.key,
    required this.index,
    required this.scrollOffset,
    required this.ambientPhase,
    required this.child,
    this.lightTier,
  });

  final int index;
  final double scrollOffset;
  final double ambientPhase;
  final Widget child;
  final OraclyLightTier? lightTier;

  @override
  Widget build(BuildContext context) {
    final profile = OraclyDiscovery.profileFor(index);
    final progress = OraclyDiscovery.revealProgress(scrollOffset, index);
    final focus = OraclyDiscovery.focusWeight(index, scrollOffset);
    final presence = TarotAtmosphere.sectionPresenceWeight(index);
    final adjustedFocus = index == 0 ? focus : focus * presence;
    final richness = OraclyDiscovery.richness(progress);
    final opacity = OraclyDiscovery.composedOpacity(progress, adjustedFocus);
    final lift = (1 - progress) * profile.lift;
    final blur = (1 - progress) * profile.maxBlur;

    final tier = lightTier ?? TarotHomeDepthSection.tierForIndex(index);

    Widget revealed = OraclyLightFalloff(
      tier: tier,
      child: child,
    );

    if (blur > 0.08) {
      revealed = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: revealed,
      );
    }

    return TarotHomeDiscoveryScope(
      revealProgress: progress,
      richness: richness,
      focusWeight: focus,
      child: Opacity(
        opacity: index == 0 ? 1.0 : opacity,
        child: Transform.translate(
          offset: Offset(0, lift),
          child: revealed,
        ),
      ),
    );
  }
}

/// Depth section anchor — pairs discovery with subtle parallax.
class TarotHomeDepthSection extends StatelessWidget {
  const TarotHomeDepthSection({
    super.key,
    required this.child,
    required this.scrollOffset,
    required this.index,
    this.lightTier,
    this.ambientPhase = 0,
  });

  final Widget child;
  final double scrollOffset;
  final int index;
  final OraclyLightTier? lightTier;
  final double ambientPhase;

  static OraclyLightTier tierForIndex(int index) {
    return switch (index) {
      0 => OraclyLightTier.orbAdjacent,
      1 => OraclyLightTier.upperChamber,
      2 => OraclyLightTier.midChamber,
      _ => OraclyLightTier.lowerChamber,
    };
  }

  @override
  Widget build(BuildContext context) {
    final phase = ambientPhase != 0
        ? ambientPhase
        : TarotHomeScrollScope.maybeOf(context)?.ambientPhase ?? 0;

    final content = TarotHomeProgressiveReveal(
      index: index,
      scrollOffset: scrollOffset,
      ambientPhase: phase,
      lightTier: lightTier,
      child: child,
    );

    if (index == 0) return content;

    final depth = index * 48.0;
    final parallax = ((scrollOffset - depth + 120) / 400).clamp(0.0, 1.0);
    final microLift = (1 - parallax) * 2;
    final scale = 1.0 - (1 - parallax) * 0.004 * index.clamp(1, 4);

    return Transform.translate(
      offset: Offset(0, microLift),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: content,
      ),
    );
  }
}

/// Exposes scroll offset to section bridges for subtle animation.
class TarotHomeScrollScope extends InheritedWidget {
  const TarotHomeScrollScope({
    super.key,
    required this.scrollOffset,
    required this.ambientPhase,
    required super.child,
  });

  final double scrollOffset;
  final double ambientPhase;

  static TarotHomeScrollScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TarotHomeScrollScope>();
  }

  @override
  bool updateShouldNotify(covariant TarotHomeScrollScope oldWidget) {
    return oldWidget.scrollOffset != scrollOffset ||
        oldWidget.ambientPhase != ambientPhase;
  }
}
