/// Soul Mate close — honesty, OR, optional continuation, redraw.
library;

import 'package:flutter/material.dart';

import '../../../../core/continuation/models/session_continuation.dart';
import '../../../../core/continuation/widgets/session_continuation_link.dart';
import '../../../../core/copy/session_ending_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import '../../../../features/ai/oracle_conversation/widgets/or_ask_button.dart';
import '../../../../features/tarot/presentation/epic031/tarot_epic031_primary_button.dart';
import '../../copy/soul_mate_copy.dart';
import '../../data/soul_mate_interpretation_catalogue.dart';

class SoulMateResultEpilogue extends StatelessWidget {
  const SoulMateResultEpilogue({
    super.key,
    required this.parts,
    required this.onRedraw,
    this.name = '',
    this.savedId,
  });

  final SoulMateReadingParts parts;
  final VoidCallback onRedraw;
  final String name;
  final String? savedId;

  @override
  Widget build(BuildContext context) {
    final oracle = OracleReadingContextSources.soulMate(
      id: savedId == null ? 'soulmate_${parts.joined.hashCode}' : 'soulmate_$savedId',
      interpretation: parts.joined,
      name: name,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SoulMateCopy.honesty,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: OraclyChrome.cream.withValues(alpha: 0.78),
            height: 1.4,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          SessionEndingCopy.footerWhisper,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: OraclyChrome.cream.withValues(alpha: 0.48),
            height: 1.35,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        OrAskButton(readingContext: oracle),
        SessionContinuationLink(
          source: SessionContinuationSource.soulMate,
          orAlreadyOffered: true,
          oracleContext: oracle,
        ),
        SizedBox(height: AppSpacing.sm),
        TarotEpic031PrimaryButton(
          label: SoulMateCopy.redrawCta,
          onPressed: onRedraw,
        ),
      ],
    );
  }
}