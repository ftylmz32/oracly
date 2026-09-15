/// Soul-mate paid draw — confirm, bind idempotency, settle once.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/security/ai_error_sanitizer.dart';
import '../../gems/copy/gems_copy.dart';
import '../../gems/models/paid_ai_operation.dart';
import '../../gems/providers/gem_providers.dart';
import '../../gems/services/gem_spend_guard.dart';
import '../../gems/services/paid_ai_operation_binder.dart';
import '../../ai/production/ai_failure.dart';
import '../copy/soul_mate_copy.dart';
import '../economy/soul_mate_economy.dart';
import '../providers/soul_mate_providers.dart';
import 'soul_mate_draw_port.dart';
import 'soul_mate_generation_policy.dart';

abstract final class SoulMatePaidDraw {
  SoulMatePaidDraw._();

  static Future<SoulMateDrawResult?> run({
    required WidgetRef ref,
    required BuildContext context,
    required SoulMateDrawRequest request,
    String? existingOperationId,
  }) async {
    // Capture before await — route dispose must not cancel a started draw.
    final coordinator = ref.read(paidAiOperationCoordinatorProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final drawPort = ref.read(soulMateDrawPortProvider);
    final wallet = ref.read(gemWalletProvider);

    final op = await GemSpendGuard.beginPaid(
      ref,
      context: context,
      feature: PaidAiFeature.soulmate,
      ledgerKey: SoulMateEconomy.ledgerKey,
      reason: GemsCopy.reasonSoulMate,
      cost: SoulMateEconomy.drawCost,
      existingId: existingOperationId,
    );
    if (op == null) return null;

    try {
      analytics.logSoulmateStarted();
    } catch (_) {}
    final started = DateTime.now();
    final result = await PaidAiOperationBinder.runWithKey(
      op.idempotencyKey,
      () => drawPort.draw(request),
    );
    if (result.hasPortrait) {
      try {
        analytics.logSoulmateSuccess(
          latency: DateTime.now().difference(started),
        );
      } catch (_) {}
      await coordinator.completeAfterProvider(op);
      try {
        wallet.reload();
      } catch (_) {}
    } else {
      await coordinator.abandon(op.id);
    }
    return result;
  }

  static String? messageFor(SoulMateDrawResult result) {
    if (result.hasPortrait || result.declined) return null;
    final kind = result.aiKind;
    if (kind == null) {
      return AiErrorSanitizer.guard(
        result.message,
        fallback: SoulMateCopy.unavailable,
      );
    }
    if (kind == AiFailureKind.unauthorized ||
        kind == AiFailureKind.appCheck ||
        kind == AiFailureKind.noConfiguration ||
        kind == AiFailureKind.authPending) {
      return AiErrorSanitizer.guard(
        result.message,
        fallback: SoulMateCopy.failureUnavailable,
      );
    }
    final failure = result.failureKind ??
        SoulMateGenerationPolicy.failureKindFor(kind);
    return switch (failure) {
      SoulMateFailureKind.connection => SoulMateCopy.failureConnection,
      SoulMateFailureKind.input => SoulMateCopy.failureInput,
      SoulMateFailureKind.unavailable => SoulMateCopy.failureUnavailable,
      SoulMateFailureKind.temporary => SoulMateCopy.failureTemporary,
    };
  }
}
