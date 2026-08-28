/// Opens the day's free next step — journal or OR, never a paywall.
library;

import 'package:flutter/material.dart';

import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import '../../../../features/ai/oracle_conversation/navigation/oracle_conversation_route.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../copy/daily_message_copy.dart';
import '../../models/daily_message.dart';
import '../../models/daily_return_action.dart';

class DailyReturnCta extends StatelessWidget {
  const DailyReturnCta({super.key, required this.action, this.message});

  final DailyReturnAction action;
  final DailyMessage? message;

  @override
  Widget build(BuildContext context) {
    return OraclyGoldButton(
      label: DailyMessageCopy.action(action),
      expanded: true,
      onPressed: () => open(context, action, message: message),
    );
  }

  static void open(
    BuildContext context,
    DailyReturnAction action, {
    DailyMessage? message,
  }) {
    switch (action) {
      case DailyReturnAction.exploreTheme:
        OraclyNavigationService.openDiscoveryJournal(context);
      case DailyReturnAction.talkToOr:
        final day = message;
        if (day != null && day.text.trim().isNotEmpty) {
          openOracleConversation(
            context,
            readingContext: OracleReadingContextSources.dailyMessage(
              text: day.text,
              dayKey: day.dateKey,
              theme: day.theme,
              sunSign: day.sunSign,
            ),
          );
          return;
        }
        OraclyNavigationService.openChat(context);
      case DailyReturnAction.drawCard:
        OraclyNavigationService.startDailyCardDraw(context);
      case DailyReturnAction.readPalm:
        OraclyNavigationService.openPalm(context);
      case DailyReturnAction.readCoffee:
        OraclyNavigationService.openCoffee(context);
      case DailyReturnAction.tellDream:
        OraclyNavigationService.openDream(context);
      case DailyReturnAction.askTarot:
        OraclyNavigationService.startDailyCardDraw(context);
      case DailyReturnAction.readAstrology:
        OraclyNavigationService.openAstrology(context);
      case DailyReturnAction.exploreStarMap:
        OraclyNavigationService.openStarMap(context);
    }
  }
}
