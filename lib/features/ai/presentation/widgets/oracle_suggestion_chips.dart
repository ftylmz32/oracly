/// OR-1190 — Suggestion chips row for first oracle message.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../oracle_conversation/services/oracle_conversation_responder.dart';
import 'suggestion_chip.dart';

class OracleSuggestionChipsRow extends StatelessWidget {
  const OracleSuggestionChipsRow({
    super.key,
    required this.onSelected,
    this.enabled = true,
    this.chips,
  });

  final ValueChanged<String> onSelected;
  final bool enabled;
  final List<String>? chips;

  @override
  Widget build(BuildContext context) {
    final labels = chips ?? OracleConversationSuggestions.chips;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          for (final label in labels) ...[
            SuggestionChip(
              label: label,
              icon: Icons.auto_awesome_rounded,
              onTap: enabled ? () => onSelected(label) : null,
            ),
            SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
