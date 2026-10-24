/// Single premium plan card — select quietly; primary CTA lives below.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/domain/models/premium_plan.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import 'premium_reference_card_shell.dart';
import 'premium_reference_tokens.dart';

class PremiumReferencePlanCard extends StatelessWidget {
  const PremiumReferencePlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final PremiumPlanModel plan;
  final bool selected;
  final VoidCallback onTap;

  static const double _indicatorWidth = 20;
  static const double _indicatorGap = 12;
  static const double _priceGap = 8;

  TextStyle get _labelStyle => AppTextStyles.title.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.goldLight.withValues(alpha: 0.94),
  );

  TextStyle get _periodStyle => AppTextStyles.caption.copyWith(
    color: AppColors.textSecondary.withValues(alpha: 0.72),
  );

  TextStyle get _priceStyle => AppTextStyles.labelMedium.copyWith(
    color: selected
        ? AppColors.gold.withValues(alpha: 0.96)
        : AppColors.gold.withValues(alpha: 0.78),
    fontWeight: FontWeight.w700,
    letterSpacing: CraftsmanshipRhythm.labelTracking,
  );

  double _width(
    BuildContext context,
    String text,
    TextStyle style,
    TextScaler scaler,
  ) {
    // Measure exactly as Text renders: merged over the inherited style.
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// True when a price beside the copy would cut the plan name or its
  /// renewal line; the store price then moves under the copy instead.
  bool _stackPrice(BuildContext context, double maxWidth) {
    if (!maxWidth.isFinite) return false;
    final scaler = MediaQuery.textScalerOf(context);
    final copyRoom = maxWidth -
        _indicatorWidth -
        _indicatorGap -
        _priceGap -
        _width(context, plan.price, _priceStyle, scaler);
    final copyNeed = [
      _width(context, plan.label, _labelStyle, scaler),
      _width(context, plan.kind.periodLabel, _periodStyle, scaler),
    ].reduce((a, b) => a > b ? a : b);
    return copyNeed > copyRoom;
  }

  @override
  Widget build(BuildContext context) {
    return PremiumReferenceCardShell(
      selected: selected,
      borderRadius: PremiumReferenceTokens.planRadius,
      padding: PremiumReferenceTokens.planPadding,
      onTap: onTap,
      glowStrength: selected ? 1.12 : 0.92,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = _stackPrice(context, constraints.maxWidth);
          final price = Text(
            plan.price,
            textAlign: stacked ? TextAlign.start : TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _priceStyle,
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SelectionIndicator(selected: selected),
              const SizedBox(width: _indicatorGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _labelStyle,
                    ),
                    if (selected) ...[
                      const SizedBox(height: 2),
                      Text(
                        PremiumCopy.planSelectedLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.gold.withValues(alpha: 0.9),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Renewal terms may wrap rather than be cut off.
                    Text(
                      plan.kind.periodLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _periodStyle,
                    ),
                    if (stacked) ...[const SizedBox(height: 6), price],
                  ],
                ),
              ),
              if (!stacked) ...[const SizedBox(width: _priceGap), price],
            ],
          );
        },
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppColors.gold
              : AppColors.gold.withValues(alpha: 0.35),
          width: AppBorderWidth.thin,
        ),
        color: selected
            ? AppColors.gold.withValues(alpha: 0.22)
            : AppColors.transparent,
      ),
      child: selected
          ? Icon(
              Icons.check_rounded,
              size: 13,
              color: AppColors.goldLight.withValues(alpha: 0.94),
            )
          : null,
    );
  }
}
