/// Coffee V3 Final Review: exactly three canonical cards (file-backed
/// thumbnails only — never bytes), intention selection, and the ONLY place
/// `beginSubmission()` may be called from. The CTA is enabled only when the
/// three photos are valid/unique/confirmed, the intention is valid, creation
/// is currently allowed and nothing is in flight. A draft opened while
/// creation is disabled stays reviewable, replaceable and cancellable.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../../../shared/widgets/oracly_quiet_link.dart';
import '../../coffee_v2/copy/coffee_v2_copy.dart';
import '../../coffee_v2/models/coffee_v2_intention.dart';
import '../../coffee_v2/presentation/coffee_v2_thumbnail.dart';
import '../../presentation/reference/coffee_capture_hint.dart';
import '../../presentation/reference/coffee_reference_tokens.dart';
import '../controllers/coffee_v3_flow_controller.dart';
import '../copy/coffee_v3_copy.dart';
import '../models/coffee_v3_photo_slot.dart';

class CoffeeV3FinalReviewView extends StatelessWidget {
  const CoffeeV3FinalReviewView({super.key, required this.controller});

  final CoffeeV3FlowController controller;

  @override
  Widget build(BuildContext context) {
    final blockMessage = switch (controller.createBlock) {
      CoffeeV3CreateBlock.creationDisabled ||
      CoffeeV3CreateBlock.serverUnavailable =>
        CoffeeV3Copy.creationUnavailable,
      CoffeeV3CreateBlock.connectionLost => CoffeeV3Copy.createConnectionLost,
      null => null,
    };
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: CoffeeReferenceTokens.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.s16),
          Text(
            CoffeeV3Copy.reviewTitle,
            textAlign: TextAlign.center,
            style: ReadingTypography.pageTitle(),
          ),
          SizedBox(height: AppSpacing.s12),
          Text(
            CoffeeV3Copy.reviewBody,
            textAlign: TextAlign.center,
            style: ReadingTypography.secondary(),
          ),
          SizedBox(height: AppSpacing.s24),
          for (final slot in coffeeV3CanonicalSlotOrder) ...[
            _ReviewCard(
              slot: slot,
              path: controller.record.slots[slot]?.asset?.path,
              onChange: () => controller.beginReplacing(slot),
            ),
            SizedBox(height: AppSpacing.s12),
          ],
          SizedBox(height: AppSpacing.s12),
          Text(
            CoffeeV2Copy.intentionTitle,
            textAlign: TextAlign.center,
            style: ReadingTypography.label(),
          ),
          SizedBox(height: AppSpacing.s8),
          Text(
            CoffeeV2Copy.intentionBody,
            textAlign: TextAlign.center,
            style: ReadingTypography.secondary(),
          ),
          SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            alignment: WrapAlignment.center,
            children: [
              for (final choice in CoffeeV2IntentionChoice.values)
                ChoiceChip(
                  label: Text(choice.label),
                  selected: choice.intention != null &&
                      controller.record.intention == choice.intention,
                  onSelected: (_) => controller.selectIntention(choice),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.s12),
          TextField(
            key: const Key('coffee-v3-custom-intention'),
            maxLength: coffeeV2IntentionMaxLength,
            onChanged: controller.setCustomIntention,
            decoration: const InputDecoration(
              hintText: CoffeeV2Copy.intentionHint,
              counterText: '',
            ),
          ),
          if (blockMessage != null) ...[
            SizedBox(height: AppSpacing.s12),
            CoffeeCaptureHint(blockMessage, attention: true),
          ],
          SizedBox(height: AppSpacing.s12),
          OraclyGoldButton(
            label: CoffeeV3Copy.reviewCta,
            expanded: true,
            onPressed: controller.canSubmit ? controller.beginSubmission : null,
          ),
          SizedBox(height: AppSpacing.s8),
          OraclyQuietLink(
            label: CoffeeV3Copy.reviewCancel,
            onTap: controller.cancelDraft,
          ),
          SizedBox(height: AppSpacing.s24),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.slot,
    required this.path,
    required this.onChange,
  });

  final CoffeeV3PhotoSlot slot;
  final String? path;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: CoffeeV3Copy.titleFor(slot),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.s8),
        decoration: BoxDecoration(
          color: OraclyChrome.midnight.withValues(alpha: 0.5),
          borderRadius: OraclyChrome.cardRadius,
          border: Border.all(
            color: OraclyChrome.goldLight.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: path == null
                  ? const SizedBox.shrink()
                  : CoffeeV2Thumbnail(path: path!),
            ),
            SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(
                CoffeeV3Copy.titleFor(slot),
                style: ReadingTypography.label(),
              ),
            ),
            OraclyQuietLink(label: CoffeeV3Copy.reviewChange, onTap: onChange),
          ],
        ),
      ),
    );
  }
}
