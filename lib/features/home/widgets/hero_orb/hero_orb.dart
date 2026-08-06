/// OR-036 — Hero orb layer assembly (reference render order).
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'orb_body.dart';
import 'orb_center.dart';
import 'orb_constants.dart';
import 'orb_effects.dart';
import 'orb_fog.dart';
import 'orb_highlight.dart';
import 'orb_logo.dart';
import 'orb_particles.dart';
import 'orb_shadow.dart';

/// Premium crystal sphere — visual centerpiece of the Home screen.
class HeroOrb extends StatefulWidget {
  const HeroOrb({
    super.key,
    this.size = AppSpacing.xxl + AppSpacing.xxl + AppSpacing.xxl + AppSpacing.lg,
  });

  final double size;

  @override
  State<HeroOrb> createState() => _HeroOrbState();
}

class _HeroOrbState extends State<HeroOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _breathe;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: OrbLayout.breathe,
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: OrbLayout.breatheScaleMin,
      end: OrbLayout.breatheScaleMax,
    ).animate(CurvedAnimation(
      parent: _breathe,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final render = OrbLayout.renderSize(widget.size);
    final sphere = OrbLayout.sphereDiameter(widget.size);

    return SizedBox(
      width: render,
      height: render,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 1 — ground shadow (always below the sphere)
              OrbShadow(size: widget.size),
              // 2 — atmospheric aura (behind crystal shell)
              OrbEffects(size: widget.size),
              // 3–8 — crystal stack (breathing)
              Transform.scale(
                scale: _scale.value,
                child: child,
              ),
            ],
          );
        },
        child: SizedBox(
          width: sphere,
          height: sphere,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.hardEdge,
            children: [
              // 3 — glass sphere shell
              OrbBody(size: widget.size),
              // 4 — internal crystal fog
              OrbFog(size: sphere),
              // 5 — golden energy core
              OrbCenter(size: widget.size),
              // 6 — floating particles (clipped to sphere)
              ClipOval(
                child: OrbParticles(size: sphere),
              ),
              // 7 — OR logo
              OrbLogo(size: widget.size),
              // 8 — glass reflections (topmost)
              OrbHighlight(size: widget.size),
            ],
          ),
        ),
      ),
    );
  }
}
