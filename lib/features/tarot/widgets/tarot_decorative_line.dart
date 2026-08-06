import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class TarotDecorativeLine extends StatelessWidget {
  const TarotDecorativeLine({super.key, this.width = 48});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.gold.withValues(alpha: 0.55),
            AppColors.goldLight.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
