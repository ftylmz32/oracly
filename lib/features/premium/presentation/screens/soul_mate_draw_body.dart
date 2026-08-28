/// Scrollable body for soul-mate draw — hero, form, wait, or portrait.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_error_state.dart';
import '../../copy/soul_mate_copy.dart';
import '../../data/soul_mate_interpretation_catalogue.dart';
import '../../services/soul_mate_draw_port.dart';
import '../../services/soul_mate_interpretation.dart';
import '../reference/premium_reference_tokens.dart';
import 'soul_mate_draw_form.dart';
import 'soul_mate_draw_result_view.dart';
import 'soul_mate_draw_waiting.dart';
import 'soul_mate_entry_hero.dart';

class SoulMateDrawBody extends StatelessWidget {
  const SoulMateDrawBody({
    super.key,
    required this.nameController,
    required this.intentionController,
    required this.birthDate,
    required this.onPickBirth,
    required this.gender,
    required this.onGender,
    required this.busy,
    required this.statusMessage,
    required this.result,
    required this.onDraw,
    required this.onRedraw,
    required this.onRetry,
    this.savedId,
  });

  final TextEditingController nameController;
  final TextEditingController intentionController;
  final DateTime? birthDate;
  final VoidCallback onPickBirth;
  final SoulMateGenderPref? gender;
  final ValueChanged<SoulMateGenderPref?> onGender;
  final bool busy;
  final String? statusMessage;
  final SoulMateDrawResult? result;
  final String? savedId;
  final VoidCallback onDraw;
  final VoidCallback onRedraw;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = !busy &&
        statusMessage != null &&
        (result == null || !result!.hasPortrait);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        PremiumReferenceTokens.screenHorizontal,
        PremiumReferenceTokens.headerToHero,
        PremiumReferenceTokens.screenHorizontal,
        AppLayout.scrollBottomInset(context),
      ),
      children: [
        const SoulMateEntryHero(),
        SizedBox(height: AppSpacing.md),
        Text(
          SoulMateCopy.screenLead,
          textAlign: TextAlign.center,
          style: ReadingTypography.footnote(
            color: OraclyChrome.cream.withValues(alpha: 0.78),
          ),
        ),
        SizedBox(height: AppSpacing.s8),
        if (busy) const SoulMateDrawWaiting(),
        if (!busy && result != null && result!.hasPortrait)
          SoulMateDrawResultView(
            imageBytes: result!.imageBytes!,
            parts: _parts,
            name: nameController.text,
            savedId: savedId,
            onRedraw: onRedraw,
          )
        else if (!busy && !failed) ...[
          SoulMateDrawForm(
            nameController: nameController,
            intentionController: intentionController,
            birthDate: birthDate,
            onPickBirth: onPickBirth,
            gender: gender,
            onGender: onGender,
            onSubmit: onDraw,
          ),
        ],
        if (failed) ...[
          SizedBox(height: AppSpacing.md),
          OraclyErrorState(
            kind: OraclyLoadingKind.soulMate,
            compact: true,
            message: statusMessage ?? SoulMateCopy.unavailable,
            onRetry: onRetry,
            retryLabel: SoulMateCopy.retry,
          ),
        ],
        if (!busy && (result == null || !result!.hasPortrait) && !failed) ...[
          SizedBox(height: AppSpacing.md),
          Text(
            SoulMateCopy.honesty,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: OraclyChrome.cream.withValues(alpha: 0.72),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  SoulMateReadingParts get _parts {
    final birth = birthDate;
    if (birth == null) {
      return const SoulMateReadingParts(
        energy: '',
        attraction: '',
        dynamics: '',
        feeling: '',
        yourSide: '',
      );
    }
    final intention = intentionController.text.trim();
    return SoulMateInterpretation.partsFor(
      SoulMateDrawRequest(
        name: nameController.text,
        birthDate: birth,
        gender: gender,
        intention: intention.isEmpty ? null : intention,
      ),
    );
  }
}
