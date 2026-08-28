/// EPIC-032 — Approved Home welcome block.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/app_colors.dart';
import '../copy/home_welcome_phrases.dart';
import 'home_epic032_spec.dart';

class HomeEpic032Welcome extends StatefulWidget {
  const HomeEpic032Welcome({
    super.key,
    this.userName = '',
    this.welcomeDay,
  });

  final String userName;
  final DateTime? welcomeDay;

  @override
  State<HomeEpic032Welcome> createState() => _HomeEpic032WelcomeState();
}

class _HomeEpic032WelcomeState extends State<HomeEpic032Welcome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = CurvedAnimation(parent: _fade, curve: Curves.easeOutCubic);
    _fade.forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = HomeEpic032Spec.isCompact(context);
    final phrase = HomeWelcomePhrases.forDay(
      day: widget.welcomeDay ?? DateTime.now(),
      salt: widget.userName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoş geldin, ${widget.userName}.',
          style: AppTypography.headingXl.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.96),
            fontWeight: FontWeight.w600,
            height: 1.12,
            letterSpacing: -0.4,
            fontSize: compact
                ? HomeEpic032Spec.welcomeTitleSizeCompact
                : HomeEpic032Spec.welcomeTitleSize,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: HomeEpic032Spec.welcomeTitleToSubtitle),
        FadeTransition(
          opacity: _opacity,
          child: Text(
            phrase,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.82),
              height: 1.45,
              letterSpacing: 0.15,
              fontWeight: FontWeight.w400,
              fontSize: compact
                  ? HomeEpic032Spec.welcomeSubtitleSizeCompact
                  : HomeEpic032Spec.welcomeSubtitleSize,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
