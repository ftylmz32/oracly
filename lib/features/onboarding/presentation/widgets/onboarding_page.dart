/// First onboarding surface — brand, windows, quiet whispers.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/onboarding_copy.dart';
import '../../../../core/design_system/app_motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/oracly_reduced_motion.dart';
import '../../../../core/theme/reading_typography.dart';
import 'onboarding_window_list.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: AppMotionDuration.normal,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (OraclyReducedMotion.of(context)) {
        _enter.value = 1;
      } else {
        _enter.forward();
      }
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = AppMotion.fade(_enter);
    final slide = AppMotion.slideUp(_enter);
    return Padding(
      padding: AppSpacing.screenHorizontal.copyWith(
        top: AppSpacing.xxl,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        children: [
          const Spacer(),
          FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: Text(
                OnboardingCopy.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          FadeTransition(
            opacity: fade,
            child: Text(
              OnboardingCopy.tagline,
              textAlign: TextAlign.center,
              style: ReadingTypography.body(color: AppColors.textSecondary),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          Text(
            OnboardingCopy.windowsLabel,
            textAlign: TextAlign.center,
            style: ReadingTypography.sectionLabel(color: AppColors.textHint),
          ),
          SizedBox(height: AppSpacing.sm),
          OnboardingWindowList(labels: OnboardingCopy.windows),
          SizedBox(height: AppSpacing.xl),
          Text(
            OnboardingCopy.orHint,
            textAlign: TextAlign.center,
            style: ReadingTypography.footnote(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            OnboardingCopy.honesty,
            textAlign: TextAlign.center,
            style: ReadingTypography.footnote(color: AppColors.textHint),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            OnboardingCopy.gemsWhisper,
            textAlign: TextAlign.center,
            style: ReadingTypography.footnote(color: AppColors.textHint),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
