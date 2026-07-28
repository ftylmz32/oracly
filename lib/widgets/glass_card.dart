import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(28),

      child: BackdropFilter(

        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),

        child: Container(

          width: double.infinity,

          padding: padding,

          decoration: BoxDecoration(

            borderRadius:
                BorderRadius.circular(28),

            gradient: LinearGradient(

              begin:
                  Alignment.topLeft,

              end:
                  Alignment.bottomRight,

              colors: [

                Colors.white.withValues(
                  alpha: .14,
                ),

                AppColors.surface.withValues(
                  alpha: .72,
                ),

              ],

            ),


            border: Border.all(

              color:
                  AppColors.glassBorder,

              width:
                  1,

            ),


            boxShadow: [

              BoxShadow(

                color:
                    Colors.black.withValues(
                      alpha: .45,
                    ),

                blurRadius:
                    35,

                offset:
                    const Offset(
                      0,
                      18,
                    ),

              ),


              BoxShadow(

                color:
                    AppColors.primary.withValues(
                      alpha: .12,
                    ),

                blurRadius:
                    40,

                spreadRadius:
                    2,

              ),

            ],

          ),

          child: child,

        ),

      ),

    );


    if (onTap == null) {

      return card;

    }


    return Material(

      color:
          Colors.transparent,

      child: InkWell(

        borderRadius:
            BorderRadius.circular(28),

        onTap:
            onTap,

        child:
            card,

      ),

    );

  }
}