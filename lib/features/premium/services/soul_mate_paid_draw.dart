/// Soul-mate paid draw — confirm, bind idempotency, settle once.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/security/ai_error_sanitizer.dart';
import '../../../../features/gems/copy/gems_copy.dart';
import '../../../../features/gems/models/paid_ai_operation.dart';
import '../../../../features/gems/providers/gem_providers.dart';
import '../../../../features/gems/services/gem_spend_guard.dart';
import '../../../../features/gems/services/paid_ai_operation_binder.dart';
import '../copy/soul_mate_copy.dart';
import '../economy/soul_mate_economy.dart';
import '../providers/soul_mate_providers.dart';
import 'soul_mate_draw_port.dart';

abstract final class SoulMatePaidDraw {
  SoulMatePaidDraw._();

  static Future<SoulMateDrawResult?> run({
    required WidgetRef ref,
    required BuildContext context,
    required SoulMateDrawRequest request,
  }) async {
    final op = await GemSpendGuard.beginPaid(
      ref,
      context: context,
      feature: PaidAiFeature.soulmate,
      ledgerKey: SoulMateEconomy.ledgerKey,
      reason: GemsCopy.reasonSoulMate,
      cost: SoulMateEconomy.drawCost,
    );
    if (op == null) return null;
    if (!context.mounted) {
      await ref.read(paidAiOperationCoordinatorProvider).abandon(op.id);
      return null;
    }
    ref.read(analyticsServiceProvider).logSoulmateStarted();
    final started = DateTime.now();
    final result = await PaidAiOperationBinder.runWithKey(
      op.idempotencyKey,
      () => ref.read(soulMateDrawPortProvider).draw(request),
    );
    if (result.hasPortrait) {
      ref.read(analyticsServiceProvider).logSoulmateSuccess(
            latency: DateTime.now().difference(started),
          );
      await GemSpendGuard.settleOperation(
        ref,
        operation: op,
        context: context.mounted ? context : null,
      );
    } else {
      await ref.read(paidAiOperationCoordinatorProvider).abandon(op.id);
    }
    return result;
  }

  static String? messageFor(SoulMateDrawResult result) {
    if (result.hasPortrait) return null;
    return AiErrorSanitizer.guard(
      result.message,
      fallback: SoulMateCopy.unavailable,
    );
  }
}
