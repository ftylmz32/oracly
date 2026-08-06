/// OR-1020 — Sticky deck confirmation footer.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../components/tarot_button.dart';

class DeckSelectionFooter extends StatelessWidget {
  const DeckSelectionFooter({
    super.key,
    required this.enabled,
    this.onConfirm,
  });

  final bool enabled;
  final VoidCallback? onConfirm;

  static const String _label = 'Bu Desteyi Seç';

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

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
              AppSpacing.md + bottom,
            ),
            child: TarotSecondaryButton(
              label: _label,
              icon: Icons.auto_awesome,
              onPressed: enabled ? onConfirm : null,
            ),
          ),
        ),
      ),
    );
  }
}
