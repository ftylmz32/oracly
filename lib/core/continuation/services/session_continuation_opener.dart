/// Opens the one suggested chamber — minimal real context when available.
library;

import 'package:flutter/material.dart';

import '../../../core/data/datasources/local_storage.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../features/ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../../features/ai/oracle_conversation/navigation/oracle_conversation_route.dart';
import '../models/session_continuation.dart';
import 'session_continuation_focus_store.dart';

abstract final class SessionContinuationOpener {
  SessionContinuationOpener._();

  static Future<void> open(
    BuildContext context,
    SessionContinuation item, {
    required LocalStorage storage,
    OracleReadingContext? oracleContext,
  }) async {
    if (item.theme != null && item.theme!.trim().isNotEmpty) {
      await SessionContinuationFocusStore(storage).write(item);
    }
    if (!context.mounted) return;
    switch (item.target) {
      case SessionContinuationTarget.tarot:
        OraclyNavigationService.startTarotFlow(context);
      case SessionContinuationTarget.discoveryJournal:
        OraclyNavigationService.openDiscoveryJournal(context);
      case SessionContinuationTarget.companion:
        if (oracleContext != null) {
          openOracleConversation(context, readingContext: oracleContext);
          return;
        }
        OraclyNavigationService.openChat(context);
    }
  }
}
