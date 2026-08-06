/// OR-026 / OR-413 — Daily energy card premium visual tokens.

library;



import 'package:flutter/material.dart';



import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_radius.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../theme/home_architecture.dart';



/// Shared decoration and spacing for the daily energy card surface.

abstract final class EnergyDecorations {

  EnergyDecorations._();



  static LinearGradient get cardSurface => HomeArchitecture.environmentDailyGlass();



  static const LinearGradient innerVignette = LinearGradient(

    begin: Alignment.topCenter,

    end: Alignment.bottomCenter,

    colors: [

      Color(0x18000000),

      Color(0x06000000),

      Color(0x14000000),

    ],

    stops: [0.0, 0.42, 1.0],

  );



  static const RadialGradient innerEdgeShadow = RadialGradient(

    center: Alignment.center,

    radius: 1.05,

    colors: [

      AppColors.transparent,

      Color(0x0E000000),

      Color(0x20000000),

    ],

    stops: [0.62, 0.88, 1.0],

  );



  static BoxDecoration get shell => HomeArchitecture.embeddedPanel(

        radius: AppRadius.lg,

        proximity: HomeOrbProximity.medium,

        goldBorderAlpha: 0.22,

      );

}



/// Typography and spacing rhythm for daily energy sections.

abstract final class EnergySpacing {

  EnergySpacing._();



  static const double titleToBody = AppSpacing.md;

  static const double bodyToAction = AppSpacing.lg;

}

