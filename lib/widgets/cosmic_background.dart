import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';


class CosmicBackground extends StatelessWidget {

  final Widget child;


  const CosmicBackground({
    super.key,
    required this.child,
  });


  @override
  Widget build(BuildContext context) {

    return Stack(

      children: [


        Container(

          decoration:
              const BoxDecoration(

            gradient:
                LinearGradient(

              begin:
                  Alignment.topCenter,

              end:
                  Alignment.bottomCenter,

              colors: [

                AppColors.backgroundTop,

                AppColors.backgroundBottom,

              ],

            ),

          ),

        ),



        CustomPaint(

          painter:
              StarPainter(),

          size:
              Size.infinite,

        ),



        child,

      ],

    );

  }

}



class StarPainter extends CustomPainter {


  @override
  void paint(
      Canvas canvas,
      Size size,
  ) {


    final random =
        Random(42);



    final softStar =
        Paint()

          ..color =
              Colors.white.withValues(
                alpha: .45,
              );



    final goldStar =
        Paint()

          ..color =
              AppColors.goldLight.withValues(
                alpha: .85,
              );



    for(
      int i = 0;
      i < 160;
      i++
    ) {


      final dx =
          random.nextDouble()
          *
          size.width;


      final dy =
          random.nextDouble()
          *
          size.height;


      final radius =
          random.nextDouble()
          *
          1.5;



      canvas.drawCircle(

        Offset(
          dx,
          dy,
        ),

        radius,

        softStar,

      );


    }



    for(
      int i = 0;
      i < 25;
      i++
    ) {


      final dx =
          random.nextDouble()
          *
          size.width;


      final dy =
          random.nextDouble()
          *
          size.height;



      canvas.drawCircle(

        Offset(
          dx,
          dy,
        ),

        2,

        goldStar,

      );

    }

  }



  @override
  bool shouldRepaint(
      CustomPainter oldDelegate,
  ) =>
      false;

}