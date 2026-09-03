/// Empty Luna — cinematic intro, then real starters (no fake history).
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../copy/companion_copy.dart';
import 'companion_feature_shortcuts.dart';
import 'companion_luna_intro_card.dart';
import 'companion_reference_prompts.dart';
import 'companion_reference_tokens.dart';

class CompanionReferenceIdle extends StatelessWidget {
  const CompanionReferenceIdle({
    super.key,
    required this.onSelected,
    this.userName = '',
    this.personality = 'mystical',
    this.kindId,
    this.contextLine,
  });

  final ValueChanged<String> onSelected;
  final String userName;
  final String personality;
  final String? kindId;
  final String? contextLine;

  @override
  Widget build(BuildContext context) {
    final short = CompanionReferenceTokens.isShortViewport(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return CompanionReferenceTokens.fillScrollPane(
          constraints: constraints,
          padding: EdgeInsets.symmetric(
            horizontal: CompanionReferenceTokens.screenHorizontal,
          ),
          alignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: short ? AppSpacing.s8 : AppSpacing.s12),
            CompanionLunaIntroCard(compact: short),
            if (contextLine != null && contextLine!.trim().isNotEmpty) ...[
              SizedBox(height: AppSpacing.s12),
              Text(
                contextLine!,
                textAlign: TextAlign.center,
                style: ReadingTypography.opening(
                  color: OraclyChrome.cream.withValues(alpha: 0.78),
                ).copyWith(fontSize: 13),
              ),
            ],
            SizedBox(height: short ? AppSpacing.s16 : AppSpacing.s24),
            CompanionReferencePrompts(
              onSelected: onSelected,
              recessed: true,
              horizontal: true,
              limit: 3,
              kindId: kindId,
            ),
            SizedBox(height: AppSpacing.s12),
            const CompanionFeatureShortcuts(),
            SizedBox(height: AppSpacing.s8),
            Text(
              CompanionCopy.idleOptional,
              textAlign: TextAlign.center,
              style: ReadingTypography.micro(
                color: OraclyChrome.goldLight.withValues(alpha: 0.55),
              ),
            ),
            SizedBox(height: AppSpacing.s16),
          ],
        );
      },
    );
  }
}
