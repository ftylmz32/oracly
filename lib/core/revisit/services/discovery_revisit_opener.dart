/// Opens a prior discovery from OR revisit actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../features/ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../../features/ai/oracle_conversation/navigation/oracle_conversation_route.dart';
import '../../../features/tarot/presentation/screens/reading_history_detail_screen.dart';
import '../../../features/tarot/presentation/utils/reading_history_mapper.dart';
import '../../../features/tarot/revisit/tarot_revisit_context.dart';
import '../../../features/tarot/revisit/tarot_revisit_intent.dart';
import '../../../features/tarot/revisit/tarot_revisit_intent_store.dart';
import '../../../features/tarot/revisit/tarot_revisit_mode.dart';
import '../../../features/tarot/revisit/tarot_revisit_service.dart';

abstract final class DiscoveryRevisitOpener {
  DiscoveryRevisitOpener._();

  static void newSpread(BuildContext context) {
    OraclyNavigationService.startTarotFlow(context);
  }

  static Future<void> openPrior(
    BuildContext context,
    TarotRevisitContext revisit,
  ) {
    return Navigator.of(context).push(
      historyDetailRoute(entry: ReadingHistoryMapper.fromModel(revisit.reading)),
    );
  }

  static Future<void> newAngle(
    BuildContext context,
    WidgetRef ref,
    TarotRevisitContext revisit,
  ) async {
    final storage = ref.read(localStorageProvider);
    await TarotRevisitIntentStore(storage).write(
      TarotRevisitIntent(
        priorReadingId: revisit.reading.id,
        mode: TarotRevisitMode.differentAngle,
        priorExcerpt: TarotRevisitService.priorExcerpt(revisit.reading),
      ),
    );
    if (!context.mounted) return;
    OraclyNavigationService.startTarotFlow(context);
  }

  static void askOr(BuildContext context, TarotRevisitContext revisit) {
    openOracleConversation(
      context,
      readingContext: OracleReadingContext.fromHistoryReading(revisit.reading),
    );
  }
}
