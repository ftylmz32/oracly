import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import 'tarot_typography.dart';

class TarotOracleHeader extends StatelessWidget {
  const TarotOracleHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(OraclyL10n.t('tarot.oracle_header'), style: TarotTypography.sectionGold(size: 16)),
        const SizedBox(height: 10),
        Container(
          height: 0.8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.gold.withValues(alpha: 0.55),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
