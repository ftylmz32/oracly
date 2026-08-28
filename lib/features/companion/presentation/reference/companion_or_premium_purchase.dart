/// Shared Premium purchase / restore finish for OR gate surfaces.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/audio/oracly_feedback_gate.dart';
import '../../../../core/audio/oracly_sound_chamber.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../premium/models/premium_purchase_result.dart';

Future<void> finishCompanionOrPremiumPurchase({
  required BuildContext context,
  required WidgetRef ref,
  required PremiumPurchaseResult result,
  bool popOnGranted = false,
}) async {
  if (!context.mounted) return;
  ref.invalidate(premiumActiveProvider);
  ref.invalidate(userProfileProvider);
  if (result.granted) {
    ref.read(analyticsServiceProvider).logPremiumActivated(
          result.plan?.name ?? 'unknown',
        );
    OraclyFeedbackGate.playCue(OraclySoundCue.premiumPurchase);
    OraclySnackBar.success(context, result.message);
    if (popOnGranted) Navigator.of(context).maybePop();
    return;
  }
  if (result.outcome == PremiumPurchaseOutcome.cancelled ||
      result.outcome == PremiumPurchaseOutcome.pending ||
      result.outcome == PremiumPurchaseOutcome.noneFound ||
      result.outcome == PremiumPurchaseOutcome.unverified) {
    OraclySnackBar.success(context, result.message);
    return;
  }
  OraclySnackBar.error(context, result.message);
}
