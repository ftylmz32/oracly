/// Empty OR — compact invitation that fits the viewport.
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';
import 'companion_or_living_core.dart';
import 'companion_or_presence.dart';
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
  // ignore: unused_field
  final String userName;
  final String personality;
  final String? kindId;
  final String? contextLine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: CompanionReferenceTokens.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          Center(
            child: CompanionOrLivingCore(
              size: CompanionReferenceTokens.idleCoreSize,
              breathe: true,
              presence: CompanionOrPresence.idle,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              CompanionCopy.idleTitle,
              textAlign: TextAlign.center,
              style: ReadingTypography.title(
                color: OraclyChrome.cream.withValues(alpha: 0.95),
              ).copyWith(fontSize: 19, height: 1.26, letterSpacing: 0.12),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              (contextLine != null && contextLine!.trim().isNotEmpty)
                  ? contextLine!
                  : CompanionCopy.idleSubtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ReadingTypography.opening(
                color: OraclyChrome.cream.withValues(
                  alpha: OraclyA11y.secondaryCream,
                ),
              ).copyWith(height: 1.45, fontSize: 13.5),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            CompanionCopy.idleOptional,
            textAlign: TextAlign.center,
            style: ReadingTypography.micro(
              color: OraclyChrome.goldLight.withValues(
                alpha: OraclyA11y.quietGoldMuted,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: CompanionReferencePrompts(
                onSelected: onSelected,
                recessed: true,
                collapsible: true,
                initialVisible: 4,
                kindId: kindId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
