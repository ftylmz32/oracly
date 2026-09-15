/// Coffee V2 Final Review (Phase 2C2 §11/§12). Exactly three canonical
/// review cards, file-backed bounded thumbnails only — never bytes/base64.
/// The CTA here is the ONLY place `beginSubmission()` may be called from.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../../../shared/widgets/oracly_quiet_link.dart';
import '../controllers/coffee_v2_flow_controller.dart';
import '../../presentation/reference/coffee_reference_tokens.dart';
import '../copy/coffee_v2_copy.dart';
import '../models/coffee_v2_photo_slot.dart';
import 'coffee_v2_thumbnail.dart';

class CoffeeV2FinalReviewView extends StatelessWidget {
  const CoffeeV2FinalReviewView({super.key, required this.controller});

  final CoffeeV2FlowController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: CoffeeReferenceTokens.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.s16),
          Text(
            CoffeeV2Copy.reviewTitle,
            textAlign: TextAlign.center,
            style: ReadingTypography.pageTitle(),
          ),
          SizedBox(height: AppSpacing.s12),
          Text(
            CoffeeV2Copy.reviewBody,
            textAlign: TextAlign.center,
            style: ReadingTypography.secondary(),
          ),
          SizedBox(height: AppSpacing.s24),
          for (final slot in coffeeV2CanonicalSlotOrder) ...[
            _ReviewCard(
              slot: slot,
              path: controller.record.slots[slot]?.asset?.path,
              onChange: () => controller.beginReplacing(slot),
            ),
            SizedBox(height: AppSpacing.s12),
          ],
          SizedBox(height: AppSpacing.s12),
          OraclyGoldButton(
            label: CoffeeV2Copy.reviewCta,
            expanded: true,
            onPressed: controller.stagingInFlight
                ? null
                : controller.beginSubmission,
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

  final CoffeeV2PhotoSlot slot;
  final String? path;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: CoffeeV2Copy.titleFor(slot),
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
                CoffeeV2Copy.titleFor(slot),
                style: ReadingTypography.label(),
              ),
            ),
            OraclyQuietLink(label: CoffeeV2Copy.reviewChange, onTap: onChange),
          ],
        ),
      ),
    );
  }
}
