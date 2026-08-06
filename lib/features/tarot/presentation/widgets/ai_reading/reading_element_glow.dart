/// OR-301+ — Soft element radial light behind the selected card.

library;



import 'dart:math' show pi, sin;



import 'package:flutter/material.dart';



import 'reading_element_theme.dart';



class ReadingElementGlow extends StatelessWidget {

  const ReadingElementGlow({

    super.key,

    required this.theme,

    required this.phase,

    this.intensity = 1,

  });



  final ReadingElementTheme theme;

  final double phase;

  final double intensity;



  @override

  Widget build(BuildContext context) {

    final breath = 0.5 + sin(phase * pi * 2) * 0.5;

    final screenWidth = MediaQuery.sizeOf(context).width;

    final glowSize = screenWidth * (0.72 + breath * 0.04);



    return Positioned.fill(

      child: RepaintBoundary(

        child: IgnorePointer(

          child: Align(

            alignment: const Alignment(0, -0.72),

            child: Container(

              width: glowSize,

              height: glowSize,

              decoration: BoxDecoration(

                shape: BoxShape.circle,

                gradient: RadialGradient(

                  colors: [

                    theme.glowColor.withValues(alpha: 0.07 * intensity),

                    theme.glowSecondary.withValues(alpha: 0.035 * intensity),

                    Colors.transparent,

                  ],

                  stops: const [0.0, 0.42, 1.0],

                ),

              ),

            ),

          ),

        ),

      ),

    );

  }

}


