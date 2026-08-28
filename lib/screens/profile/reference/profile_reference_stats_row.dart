/// Reference statistics row — readings · dreams · astrology.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'profile_reference_card_shell.dart';
import 'profile_reference_tokens.dart';

class ProfileReferenceStatsRow extends StatelessWidget {
  const ProfileReferenceStatsRow({
    super.key,
    required this.readingCount,
    required this.dreamCount,
    required this.astrologyCount,
  });

  final int readingCount;
  final int dreamCount;
  final int astrologyCount;

  static const _stats = [
    _StatSpec(label: 'Okuma', icon: Icons.auto_stories_rounded),
    _StatSpec(label: 'Rüya', icon: Icons.nightlight_round),
    _StatSpec(label: 'Astroloji', icon: Icons.auto_awesome_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final values = [readingCount, dreamCount, astrologyCount];

    return Row(
      children: [
        for (var i = 0; i < _stats.length; i++) ...[
          if (i > 0) SizedBox(width: ProfileReferenceTokens.statGap),
          Expanded(
            child: ProfileReferenceCardShell(
              height: ProfileReferenceTokens.statCardHeight,
              borderRadius: ProfileReferenceTokens.statRadius,
              padding: ProfileReferenceTokens.statCardPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _stats[i].icon,
                    size: 16,
                    color: palette.goldLight.withValues(alpha: 0.82),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${values[i]}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.title.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: palette.goldLight.withValues(alpha: 0.94),
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _stats[i].label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: palette.textSecondary.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                      height: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatSpec {
  const _StatSpec({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
