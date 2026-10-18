/// What a Premium sheet tap is allowed to do. Never a purchase.
library;

import '../../../../core/copy/premium_copy.dart';
import '../../models/premium_models.dart';

enum PremiumEntryFocus { general, soulMate, journey }

enum PremiumEntryIntent { dismiss, plans, inspect }

/// Store truth for the sheet. Preview flags exist only on the debug QA path.
({bool checking, bool canBuy, bool showClosed}) premiumEntryGate({
  required bool loaded,
  required bool purchaseConfigured,
  required bool checkingStore,
  required bool storeOffersPlans,
  required bool isPremium,
  required bool previewClosed,
  required bool previewPlans,
}) {
  final checking = previewClosed || previewPlans
      ? false
      : purchaseConfigured && (!loaded || checkingStore);
  final canBuy = previewPlans
      ? true
      : previewClosed
          ? false
          : loaded && storeOffersPlans && !isPremium;
  final showClosed = previewClosed ||
      (!previewPlans &&
          !isPremium &&
          !checking &&
          (!purchaseConfigured || (loaded && !storeOffersPlans)));
  return (checking: checking, canBuy: canBuy, showClosed: showClosed);
}

PremiumBenefit premiumFocusedBenefit(PremiumEntryFocus focus) {
  final action = focus == PremiumEntryFocus.soulMate
      ? PremiumBenefitAction.soulMate
      : PremiumBenefitAction.journey;
  return PremiumCatalogue.concretePremiumExperiences
      .firstWhere((benefit) => benefit.action == action);
}

/// Null while the store is still being checked, or when this page already
/// explains a closed store.
String? premiumEntryActionLabel({
  required bool checking,
  required bool canBuy,
  required bool alreadyHere,
}) {
  if (checking) return null;
  if (canBuy) return PremiumCopy.seePlans;
  if (alreadyHere) return null;
  return PremiumCopy.ctaInspect;
}
