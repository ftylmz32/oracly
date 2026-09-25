/// History detail scroll body — 7E result experience, no live ritual chrome.
library;

import 'package:flutter/material.dart';

import '../../../../core/domain/models/reading.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/tarot_spread.dart';
import '../../theme/tarot_tokens.dart';
import '../widgets/ai_reading/ai_reading_content.dart';
import '../widgets/ai_reading/reading_premium_body.dart';
import '../widgets/ai_reading/reading_result_mode.dart';
import '../widgets/reading_history/reading_history_data.dart';
import '../widgets/reading_history/reading_journal_keyword_chips.dart';
import '../widgets/reading_history/reading_journal_reflection_card.dart';

class ReadingHistoryDetailBody extends StatelessWidget {
  const ReadingHistoryDetailBody({
    super.key,
    required this.entry,
    required this.model,
    required this.content,
    required this.personalNote,
    required this.onEditReflection,
    required this.onDelete,
  });

  final ReadingHistoryEntry entry;
  final ReadingModel? model;
  final AiReadingContent content;
  final String? personalNote;
  final VoidCallback onEditReflection;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final spread = TarotSpreadType.fromPersisted(
      model?.spreadType ?? entry.spreadType,
    );
    final modeOverride = ReadingResultModeResolver.parsePersisted(
          model?.resultMode,
        ) ??
        ReadingResultMode.legacy;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: TarotTokens.screenPaddingOf(context).copyWith(top: 0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: TarotTokens.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (entry.emotionalKeywords.isNotEmpty) ...[
                ReadingJournalKeywordChips(keywords: entry.emotionalKeywords),
                SizedBox(height: AppSpacing.md),
              ],
              ReadingJournalReflectionCard(
                note: personalNote,
                onEdit: onEditReflection,
              ),
              SizedBox(height: AppSpacing.lg),
              ReadingPremiumBody(
                content: content,
                spread: spread,
                sectionMaster: 1,
                panelOpacity: 1,
                ambientPhase: 0,
                modeOverride: modeOverride,
                showFlowProgress: false,
              ),
              SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                  label: Text(
                    OraclyL10n.t('tarot.history.delete_reflection'),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
