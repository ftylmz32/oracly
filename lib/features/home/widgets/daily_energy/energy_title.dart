/// OR-004.1 / OR-026 — Daily energy card header title.

library;



import 'package:flutter/material.dart';



import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_text_styles.dart';



/// Uppercase card heading — moon phase slot reserved on the right.

class EnergyTitle extends StatelessWidget {

  const EnergyTitle({super.key});



  static const String _title = 'GÜNLÜK ENERJİN';



  @override

  Widget build(BuildContext context) {

    return Row(

      children: [

        Expanded(

          child: Text(

            _title,

            style: AppTextStyles.labelLarge.copyWith(

              color: AppColors.goldLight.withValues(alpha: 0.86),

              fontWeight: FontWeight.w600,

              letterSpacing: 1.0,

              height: 1.32,

            ),

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

          ),

        ),

      ],

    );

  }

}

