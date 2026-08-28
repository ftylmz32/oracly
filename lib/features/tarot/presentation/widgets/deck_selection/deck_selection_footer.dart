/// OR-1020 — Sticky deck confirmation footer.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/design_system/app_layout.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../gems/copy/gems_copy.dart';
import '../../../copy/tarot_l10n.dart';
import '../../../components/tarot_button.dart';

class DeckSelectionFooter extends StatelessWidget {
  const DeckSelectionFooter({
    super.key,
    required this.enabled,
    this.cost,
    this.onConfirm,
  });

  final bool enabled;
  final int? cost;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.0),
                AppColors.background.withValues(alpha: 0.88),
                AppColors.background.withValues(alpha: 0.96),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.12),
                width: AppBorderWidth.hairline,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppLayout.scrollBottomInset(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cost != null && cost! > 0) ...[
                  Text(
                    GemsCopy.costLabel(cost!),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.goldLight.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.35,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                ],
                TarotSecondaryButton(
                  label: TarotL10n.chooseDeck,
                  icon: Icons.auto_awesome,
                  onPressed: enabled ? onConfirm : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
