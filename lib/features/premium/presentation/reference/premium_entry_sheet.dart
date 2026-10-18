library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/ui/oracly_bottom_sheet.dart';
import '../../providers/premium_providers.dart';
import 'premium_entry_action.dart';
import 'premium_quiet_action.dart';
import 'premium_reference_experience_card.dart';
import 'premium_unlock_list.dart';

export 'premium_entry_action.dart';

abstract final class PremiumEntrySheet {
  PremiumEntrySheet._();

  static Future<PremiumEntryIntent> show(
    BuildContext context, {
    PremiumEntryFocus focus = PremiumEntryFocus.general,
    bool alreadyHere = false,
    bool previewClosed = false,
    bool previewPlans = false,
  }) async {
    final result = await OraclyBottomSheet.show<PremiumEntryIntent>(
      context,
      title: _title(focus),
      child: PremiumEntryBody(
        popBeforeOpen: true,
        focus: focus,
        alreadyHere: alreadyHere,
        previewClosed: previewClosed,
        previewPlans: previewPlans,
      ),
    );
    return result ?? PremiumEntryIntent.dismiss;
  }

  static String _title(PremiumEntryFocus focus) => switch (focus) {
        PremiumEntryFocus.soulMate => PremiumCopy.benefitSoulmateTitle,
        PremiumEntryFocus.journey => PremiumCopy.benefitJourneyTitle,
        PremiumEntryFocus.general => PremiumCopy.gateTitle,
      };
}

class PremiumEntryBody extends ConsumerWidget {
  const PremiumEntryBody({
    super.key,
    this.showCta = true,
    this.popBeforeOpen = false,
    this.alreadyHere = false,
    this.previewClosed = false,
    this.previewPlans = false,
    this.focus = PremiumEntryFocus.general,
  });

  final bool showCta;
  final bool popBeforeOpen;
  final bool alreadyHere;
  final bool previewClosed;
  final bool previewPlans;
  final PremiumEntryFocus focus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(premiumStatusProvider);
    final gate = premiumEntryGate(
      loaded: status.loaded,
      purchaseConfigured: status.purchaseConfigured,
      checkingStore: status.checkingStore,
      storeOffersPlans: status.storeOffersPlans,
      isPremium: status.isPremium,
      previewClosed: previewClosed,
      previewPlans: previewPlans,
    );
    final label = showCta
        ? premiumEntryActionLabel(
            checking: gate.checking,
            canBuy: gate.canBuy,
            alreadyHere: alreadyHere,
          )
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (focus != PremiumEntryFocus.general) ...[
            PremiumReferenceExperienceCard(
              benefit: premiumFocusedBenefit(focus),
              locked: true,
            ),
            SizedBox(height: AppSpacing.md),
          ],
          if (focus == PremiumEntryFocus.general) ...[
            Text(
              PremiumCopy.gateLead,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: OraclyChrome.cream.withValues(alpha: 0.78),
                height: 1.4,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            const PremiumUnlockList(compact: true),
          ],
          if (gate.checking || gate.showClosed) ...[
            SizedBox(height: AppSpacing.md),
            Text(
              gate.checking
                  ? PremiumCopy.ctaCheckingStore
                  : PremiumCopy.ctaUnavailable,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: OraclyChrome.goldLight.withValues(alpha: 0.82),
                height: 1.35,
              ),
            ),
          ],
          if (label != null) ...[
            SizedBox(height: AppSpacing.md),
            Align(
              child: PremiumQuietAction(
                label: label,
                onTap: () {
                  if (popBeforeOpen) {
                    Navigator.of(context).pop(
                      gate.canBuy
                          ? PremiumEntryIntent.plans
                          : PremiumEntryIntent.inspect,
                    );
                  }
                  if (!alreadyHere) {
                    OraclyNavigationService.openPremium(context);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
