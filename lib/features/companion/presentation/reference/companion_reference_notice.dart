/// Calm OR notice — request failure only; never a Material red panel.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/async_state/oracly_async_emblem.dart';
import '../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/security/ai_error_sanitizer.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_text_action.dart';
import '../../copy/companion_copy.dart';
import 'companion_reference_tokens.dart';

/// Kept for compatibility — always stays inside the chat shell.
class CompanionReferenceErrorBody extends StatelessWidget {
  const CompanionReferenceErrorBody({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return CompanionReferenceNotice(
      message: message ?? CompanionCopy.connectionError,
      onRetry: onRetry,
      compact: true,
    );
  }
}

class CompanionReferenceNotice extends StatelessWidget {
  const CompanionReferenceNotice({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final copy = AiErrorSanitizer.guard(
      message,
      fallback: CompanionCopy.connectionError,
    );
    return Padding(
      padding: compact
          ? EdgeInsets.fromLTRB(
              CompanionReferenceTokens.screenHorizontal,
              AppSpacing.s8,
              CompanionReferenceTokens.screenHorizontal,
              0,
            )
          : AppSpacing.screenHorizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const OraclyAsyncEmblem(
            kind: OraclyLoadingKind.orPresence,
            size: 36,
            amber: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              copy,
              textAlign: TextAlign.start,
              style: ReadingTypography.bodySmall(
                color: OraclyChrome.cream.withValues(alpha: 0.78),
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            OraclyTextAction(
              label: CompanionCopy.retry,
              emphasized: true,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
