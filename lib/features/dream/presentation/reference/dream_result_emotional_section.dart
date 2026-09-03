/// Emotional reading section with optional tags.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/dream_copy.dart';
import 'dream_result_premium_card.dart';

class DreamResultEmotionalSection extends StatelessWidget {
  const DreamResultEmotionalSection({
    super.key,
    required this.body,
    this.tags = const [],
  });

  final String body;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    return DreamResultPremiumCard(
      title: DreamCopy.resultEmotionalTitle,
      body: body,
      icon: Icons.favorite_outline_rounded,
      child: tags.isEmpty
          ? null
          : Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final tag in tags)
                    Text(
                      tag,
                      style: ReadingTypography.footnote(
                        color: OraclyChrome.goldLight.withValues(alpha: 0.78),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
