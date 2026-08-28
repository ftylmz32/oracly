/// Starts a reading from the tarot entry chamber.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/app_providers.dart';
import '../../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../gems/services/gem_spend_guard.dart';
import '../../../domain/models/tarot_spread.dart';
import '../../../economy/tarot_economy.dart';
import '../../../reading/reading_question.dart';
import '../../../shared/tarot_scope.dart';
import '../../../revisit/tarot_revisit_intent.dart';
import '../../../revisit/tarot_revisit_intent_store.dart';

abstract final class TarotEntryLaunch {
  TarotEntryLaunch._();

  static Future<bool> start({
    required BuildContext context,
    required WidgetRef ref,
    required TarotSpreadType spread,
    required String question,
    TarotRevisitIntent? revisit,
  }) async {
    final allowed = GemSpendGuard.ensureAffordable(
      ref,
      context: context,
      cost: TarotEconomy.costFor(spread),
    );
    if (!allowed) return false;

    OraclyNavigationService.logScreen(ref, 'tarot_home_start');
    if (!context.mounted) return false;

    if (revisit != null) {
      await TarotRevisitIntentStore(
        ref.read(localStorageProvider),
      ).write(revisit);
    }
    if (!context.mounted) return false;

    final scope = TarotScope.maybeOf(context);
    scope?.flow.selectSpread(spread);
    scope?.flow.captureIntention(
      TarotIntention(
        text: ReadingQuestion.sanitize(question),
        topic: 'general',
      ),
    );
    if (!context.mounted) return false;
    // Spread start is logged after deck confirm — not here (pre-confirm).
    ref.read(selectedSpreadProvider.notifier).state = spread.label;
    OraclyNavigationService.startTarotFlow(context, spreadType: spread.label);
    return true;
  }
}
