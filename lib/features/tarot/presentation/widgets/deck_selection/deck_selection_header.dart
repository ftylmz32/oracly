/// OR-1020 — Deck selection screen header.
library;

import 'package:flutter/material.dart';

import '../../../components/tarot_header.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/oracly_signature_motifs.dart';

class DeckSelectionHeader extends StatelessWidget {
  const DeckSelectionHeader({super.key});

  static const String _title = 'TAROT DESTESİ';
  static const String _subtitle =
      'Kartlar seni seçmeden önce sen niyetini belirle.';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TarotHeaderBackButton(onPressed: () => Navigator.maybePop(context)),
          Expanded(
            child: Column(
              children: [
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    _subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const OraclySignatureDivider(compact: true),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.xxl + AppSpacing.sm),
        ],
      ),
    );
  }
}
