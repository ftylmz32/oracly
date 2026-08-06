/// OR-004.2 / OR-026 — Daily energy card description copy.

library;



import 'package:flutter/material.dart';



import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_text_styles.dart';



/// Three-line explanatory text beneath the daily energy title.

class EnergyDescription extends StatelessWidget {

  const EnergyDescription({

    super.key,

    required this.description,

  });



  final String description;



  @override

  Widget build(BuildContext context) {

    return Text(

      description,

      style: AppTextStyles.bodySmall.copyWith(

        color: AppColors.textSecondary.withValues(alpha: 0.94),

        height: 1.58,

        letterSpacing: 0.22,

      ),

      maxLines: 3,

      overflow: TextOverflow.ellipsis,

      textAlign: TextAlign.left,

    );

  }

}

