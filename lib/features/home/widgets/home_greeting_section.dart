/// EPIC-022 — Greeting block: large headline + rotating subtitle.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_layout.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import 'home_welcome_subtitle.dart';

/// Typography hierarchy matching the concept — generous vertical rhythm.
class HomeGreetingSection extends StatelessWidget {
  const HomeGreetingSection({
    super.key,
    this.userName = '',
    this.welcomeDay,
  });

  final String userName;
  final DateTime? welcomeDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoş geldin, $userName.',
          style: AppTypography.headingXl.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.96),
            fontWeight: FontWeight.w600,
            height: 1.12,
            letterSpacing: -0.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: AppLayout.titleToSubtitle),
        HomeWelcomeSubtitle(
          userName: userName,
          day: welcomeDay,
        ),
      ],
    );
  }
}
