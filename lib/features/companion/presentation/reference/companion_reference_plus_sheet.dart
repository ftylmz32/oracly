/// Plus sheet — the same real starter messages as the empty state.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';
import 'companion_reference_prompts.dart';

Future<void> showCompanionPromptSheet({
  required BuildContext context,
  required ValueChanged<String> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.s20,
            color: OraclyChrome.elevatedSurface.withValues(alpha: 0.96),
            border: Border.all(
              color: OraclyChrome.gold.withValues(alpha: 0.28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CompanionCopy.plusLabel,
                    style: ReadingTypography.sectionLabel(),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  CompanionReferencePrompts(
                    recessed: true,
                    limit: CompanionCopy.suggestions.length,
                    onSelected: (value) {
                      Navigator.of(sheetContext).pop();
                      onSelected(value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
