/// Dream paid analyze — confirm, bind idempotency, settle once.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../features/gems/copy/gems_copy.dart';
import '../../../../features/gems/models/paid_ai_operation.dart';
import '../../../../features/gems/providers/gem_providers.dart';
import '../../../../features/gems/services/gem_spend_guard.dart';
import '../../../../features/gems/services/paid_ai_operation_binder.dart';
import '../../personal_discovery/services/personal_discovery_refresh.dart';
import '../controllers/dream_analysis_controller.dart';
import '../economy/dream_economy.dart';
import '../models/dream_emotion.dart';

abstract final class DreamPaidSubmit {
  DreamPaidSubmit._();

  static bool _running = false;

  static Future<void> run({
    required WidgetRef ref,
    required BuildContext context,
    required DreamAnalysisController controller,
    required String narrative,
    required List<DreamEmotion> emotions,
    required List<String> tags,
  }) async {
    if (_running) return;
    _running = true;
    try {
      final op = await GemSpendGuard.beginPaid(
        ref,
        context: context,
        feature: PaidAiFeature.dream,
        ledgerKey: DreamEconomy.ledgerKey,
        reason: GemsCopy.reasonDream,
        cost: DreamEconomy.analysisCost,
      );
      if (op == null) return;
      if (!context.mounted) {
        await ref.read(paidAiOperationCoordinatorProvider).abandon(op.id);
        return;
      }
      ref.read(analyticsServiceProvider).logDreamStarted();
      final started = DateTime.now();
      await PaidAiOperationBinder.runWithKey(op.idempotencyKey, () {
        return controller.submit(
          narrative: narrative,
          emotions: emotions,
          tags: tags,
        );
      });
      if (controller.phase == DreamJourneyPhase.complete) {
        ref.read(analyticsServiceProvider).logDreamCompleted(
              latency: DateTime.now().difference(started),
            );
        await GemSpendGuard.settleOperation(
          ref,
          operation: op,
          context: context.mounted ? context : null,
        );
        if (context.mounted) PersonalDiscoveryRefresh.invalidate(ref);
      } else {
        await ref.read(paidAiOperationCoordinatorProvider).abandon(op.id);
      }
    } finally {
      _running = false;
    }
  }
}
