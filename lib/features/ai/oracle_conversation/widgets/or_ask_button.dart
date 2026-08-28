/// Shared OR'a Sor CTA — opens the canonical OR chat with reading context.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/conversation_copy.dart';
import '../../../tarot/presentation/epic031/tarot_epic031_primary_button.dart';
import '../models/oracle_reading_context.dart';
import '../navigation/oracle_conversation_route.dart';

class OrAskButton extends StatelessWidget {
  const OrAskButton({
    super.key,
    required this.readingContext,
    this.label,
  });

  final OracleReadingContext readingContext;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return TarotEpic031PrimaryButton(
      label: label ?? ConversationCopy.askOr,
      onPressed: () => openOracleConversation(
        context,
        readingContext: readingContext,
      ),
    );
  }
}
