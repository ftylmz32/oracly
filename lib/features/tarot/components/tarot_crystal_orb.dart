/// OR-1010 — Tarot-specific premium crystal orb.

library;



import 'package:flutter/material.dart';



import '../theme/tarot_tokens.dart';

import '../presentation/painters/tarot_crystal_orb_painter.dart';



/// Large mystical crystal sphere — distinct from the Home hero orb.

class TarotCrystalOrb extends StatefulWidget {

  const TarotCrystalOrb({

    super.key,

    this.size = TarotTokens.homeOrbSize,

  });



  final double size;



  @override

  State<TarotCrystalOrb> createState() => _TarotCrystalOrbState();

}



class _TarotCrystalOrbState extends State<TarotCrystalOrb>

    with TickerProviderStateMixin {

  late final AnimationController _glow;

  late final AnimationController _float;

  late final AnimationController _particles;



  @override

  void initState() {

    super.initState();

    _glow = AnimationController(

      vsync: this,

      duration: const Duration(seconds: 9),

    )..repeat(reverse: true);

    _float = AnimationController(

      vsync: this,

      duration: const Duration(seconds: 14),

    )..repeat(reverse: true);

    _particles = AnimationController(

      vsync: this,

      duration: const Duration(seconds: 56),

    )..repeat();

  }



  @override

  void dispose() {

    _glow.dispose();

    _float.dispose();

    _particles.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return RepaintBoundary(

      child: AnimatedBuilder(

        animation: Listenable.merge([_glow, _float, _particles]),

        builder: (context, _) {

          final floatT = Curves.easeInOut.transform(
            _float.value.clamp(0.0, 1.0),
          );

          final dy = (floatT * 2 - 1) * 3;

          final scale = 0.988 +
              Curves.easeInOut.transform(_glow.value.clamp(0.0, 1.0)) * 0.024;



          return Transform.translate(

            offset: Offset(0, dy),

            child: Transform.scale(

              scale: scale,

              child: SizedBox(

                width: widget.size,

                height: widget.size,

                child: CustomPaint(

                  painter: TarotCrystalOrbPainter(

                    glowPhase: _glow.value,

                    particlePhase: _particles.value * 6.28,

                  ),

                ),

              ),

            ),

          );

        },

      ),

    );

  }

}


