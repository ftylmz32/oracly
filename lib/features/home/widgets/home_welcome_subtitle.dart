/// EPIC-018 — Rotating mystical welcome subtitle beneath the home greeting.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../copy/home_welcome_phrases.dart';

/// Daily-rotating welcome line — soft fade on first appearance.
class HomeWelcomeSubtitle extends StatefulWidget {
  const HomeWelcomeSubtitle({
    super.key,
    required this.userName,
    this.day,
  });

  final String userName;
  final DateTime? day;

  @override
  State<HomeWelcomeSubtitle> createState() => _HomeWelcomeSubtitleState();
}

class _HomeWelcomeSubtitleState extends State<HomeWelcomeSubtitle>
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
    _opacity = CurvedAnimation(
      parent: _fade,
      curve: Curves.easeOutCubic,
    );
    _fade.forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phrase = HomeWelcomePhrases.forDay(
      day: widget.day ?? DateTime.now(),
      salt: widget.userName,
    );

    return FadeTransition(
      opacity: _opacity,
      child: Text(
        phrase,
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textSecondary.withValues(alpha: 0.82),
          height: 1.62,
          letterSpacing: 0.2,
          fontWeight: FontWeight.w400,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
