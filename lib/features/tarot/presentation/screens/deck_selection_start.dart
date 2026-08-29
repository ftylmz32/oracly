/// TAROT V2 — check gems here; spend only after a successful reading.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/first_session/first_session_intent.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../gems/copy/gems_copy.dart';
import '../../../gems/services/gem_spend_guard.dart';
import '../../domain/models/tarot_spread.dart';
import '../../economy/tarot_economy.dart';
import '../../first_session/tarot_first_reading.dart';
import '../../../companion/services/first_reading_or_deepen.dart';
import '../../shared/tarot_scope.dart';
import '../widgets/deck_selection/deck_selection_data.dart';
import '../widgets/deck_selection/deck_selection_premium_gate.dart';

abstract final class DeckSelectionStart {
  DeckSelectionStart._();

  static Future<bool> confirm({
    required BuildContext context,
    required WidgetRef ref,
    required String deckId,
    bool openShuffleRoute = true,
  }) async {
    final chosen = TarotDeckCatalogue.decks
        .where((d) => d.id == deckId)
        .firstOrNull;
    if (chosen == null ||
        !TarotDeckCatalogue.isSelectable(deckId) ||
        !DeckSelectionPremiumGate.allow(context, chosen)) {
      return false;
    }
    final scope = TarotScope.of(context);
    final spread = scope.flow.spread;
    final spreadTitle = ref.read(selectedSpreadProvider) ?? spread.label;
    final spreadType = TarotSpreadType.fromTitle(spreadTitle) ?? spread;
    final cost = TarotEconomy.costFor(spreadType);
    final allowed = GemSpendGuard.ensureAffordable(
      ref,
      context: context,
      cost: cost,
    );
    if (!allowed || !context.mounted) return false;
    if (!await GemSpendGuard.confirmCost(
      ref,
      context,
      cost: cost,
      reason: GemsCopy.reasonTarot,
    )) {
      return false;
    }
    if (!context.mounted) return false;
    ref
        .read(analyticsServiceProvider)
        .logTarotStarted(spreadType: spreadType.name);
    if (cost != null && cost > 0) {
      ref.read(analyticsServiceProvider).logGemPurchaseStarted(reason: 'tarot');
    }

    ref.read(selectedDeckProvider.notifier).state = deckId;
    await ref.read(tarotServiceProvider).selectDeck(deckId);
    if (!context.mounted) return false;

    await scope.reading.beginSession(
      spread: spreadType,
      deckId: deckId,
      intention: scope.flow.intention,
    );
    await scope.reading.advanceToShuffle();
    if (!context.mounted) return false;

    // First-session single card: capture OR deepen eligibility, then consume
    // the pending Home CTA intent (intent is gone by reading result time).
    if (spreadType == TarotFirstReading.spread) {
      final storage = ref.read(localStorageProvider);
      if (FirstSessionIntent.isPending(storage)) {
        final sessionId = scope.reading.session?.id;
        if (sessionId != null) {
          await FirstReadingOrDeepen.markEligible(storage, sessionId);
        }
        await FirstSessionIntent.consumePendingFirstReading(storage);
        ref.read(firstReadingPendingProvider.notifier).state = false;
      }
    }
    if (!context.mounted) return false;

    if (openShuffleRoute) {
      OraclyNavigationService.openShuffle(context);
    }
    return true;
  }
}
