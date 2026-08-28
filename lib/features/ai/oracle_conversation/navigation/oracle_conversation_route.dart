/// Feature handoff entry — always opens the canonical OR chat.
library;

import 'package:flutter/material.dart';

import '../../../../core/navigation/oracly_navigation_service.dart';
import '../models/oracle_reading_context.dart';

/// Opens the same OR screen as Home → OR, with a compact reading handoff.
void openOracleConversation(
  BuildContext context, {
  required OracleReadingContext readingContext,
}) {
  OraclyNavigationService.openChat(
    context,
    readingContext: readingContext,
  );
}