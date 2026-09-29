/// Purchase and restore feedback — suppressed when the owner has changed.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/audio/oracly_feedback_gate.dart';
import '../../../../core/audio/oracly_sound_chamber.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../models/premium_purchase_result.dart';

Future<void> finishPremiumReferenceOutcome(
  WidgetRef ref,
  BuildContext context,
  PremiumPurchaseResult result, {
  required bool restore,
}) async {
  final analytics = ref.read(analyticsServiceProvider);
  ref.invalidate(premiumActiveProvider);
  ref.invalidate(userProfileProvider);
  if (result.granted) {
    analytics.logPremiumActivated(result.plan?.name ?? 'unknown');
    analytics.logOperation(
      operation: restore
          ? 'premium_restore_completed'
          : 'premium_purchase_completed',
      success: true,
    );
    OraclyFeedbackGate.playCue(OraclySoundCue.premiumPurchase);
    OraclySnackBar.success(context, result.message);
    return;
  }
  final cancelled = result.outcome == PremiumPurchaseOutcome.cancelled;
  final pending = result.outcome == PremiumPurchaseOutcome.pending;
  final noneFound = result.outcome == PremiumPurchaseOutcome.noneFound;
  final unverified = result.outcome == PremiumPurchaseOutcome.unverified;
  final soft = cancelled || pending || noneFound;
  analytics.logOperation(
    operation: restore
        ? 'premium_restore_completed'
        : cancelled
        ? 'premium_purchase_cancelled'
        : 'premium_purchase_failed',
    success: soft,
    errorCategory: result.outcome.name,
  );
  if (unverified) {
    OraclySnackBar.error(context, result.message);
    return;
  }
  if (soft) {
    OraclySnackBar.success(context, result.message);
    return;
  }
  OraclySnackBar.error(context, result.message);
}
