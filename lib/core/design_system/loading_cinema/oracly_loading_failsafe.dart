/// Honest slow-response recovery — never fake percentages.
library;

import 'package:flutter/material.dart';

import '../../../shared/widgets/oracly_gold_button.dart';
import '../../copy/resilience_copy.dart';
import '../../theme/reading_typography.dart';
import '../async_state/oracly_async_emblem.dart';
import '../oracly_chrome.dart';
import 'oracly_loading_kind.dart';

class OraclyLoadingFailsafe extends StatelessWidget {
  const OraclyLoadingFailsafe({
    super.key,
    this.onRetry,
    this.kind = OraclyLoadingKind.chamber,
  });

  final VoidCallback? onRetry;
  final OraclyLoadingKind kind;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OraclyAsyncEmblem(kind: kind, size: 72, amber: true),
          const SizedBox(height: 16),
          Text(
            ResilienceCopy.slowResponse,
            textAlign: TextAlign.center,
            style: ReadingTypography.body(
              color: OraclyChrome.cream.withValues(alpha: 0.88),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            OraclyGoldButton(
              label: ResilienceCopy.retryAction,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
