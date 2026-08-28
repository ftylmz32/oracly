/// Subtle OR link status — never a full-screen lock.
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_text_action.dart';
import '../../copy/companion_copy.dart';
import '../../models/companion_state.dart';
import 'companion_reference_tokens.dart';

class CompanionConnectionStrip extends StatelessWidget {
  const CompanionConnectionStrip({
    super.key,
    required this.status,
    this.onRetry,
  });

  final CompanionLinkStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == CompanionLinkStatus.online) {
      return const SizedBox.shrink();
    }

    final connecting = status == CompanionLinkStatus.connecting ||
        status == CompanionLinkStatus.reconnecting;
    final label = switch (status) {
      CompanionLinkStatus.reconnecting => CompanionCopy.reconnecting,
      CompanionLinkStatus.connecting => CompanionCopy.connecting,
      _ => CompanionCopy.offline,
    };

    return Semantics(
      liveRegion: true,
      label: label,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          CompanionReferenceTokens.screenHorizontal,
          AppSpacing.s8,
          CompanionReferenceTokens.screenHorizontal,
          0,
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: connecting
                      ? OraclyA11y.goldReadable(OraclyChrome.goldLight)
                      : OraclyChrome.cream.withValues(
                          alpha: OraclyA11y.hintCream,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: ReadingTypography.bodyCore(
                  color: OraclyChrome.cream.withValues(
                    alpha: connecting
                        ? OraclyA11y.secondaryCream
                        : OraclyA11y.hintCream,
                  ),
                ).copyWith(fontSize: 12, height: 1.2),
              ),
            ),
            if (!connecting && onRetry != null)
              OraclyTextAction(
                label: CompanionCopy.retry,
                emphasized: true,
                onPressed: onRetry,
              ),
          ],
        ),
      ),
    );
  }
}
