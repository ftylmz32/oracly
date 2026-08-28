/// Cinematic error / offline / retry — feature atmosphere, never Material red.
library;

import 'package:flutter/material.dart';

import '../../core/copy/resilience_copy.dart';
import '../../core/design_system/async_state/oracly_async_emblem.dart';
import '../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../core/design_system/oracly_chrome.dart';
import '../../core/design_system/premium_button.dart';
import '../../core/security/ai_error_sanitizer.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/reading_typography.dart';
import 'oracly_text_action.dart';

class OraclyErrorState extends StatelessWidget {
  const OraclyErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title,
    this.compact = false,
    this.secondaryLabel,
    this.onSecondary,
    this.retryLabel,
    this.kind = OraclyLoadingKind.chamber,
    this.offline = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? title;
  final bool compact;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? retryLabel;
  final OraclyLoadingKind kind;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final body = AiErrorSanitizer.guard(
      message,
      fallback: offline
          ? ResilienceCopy.offline
          : ResilienceCopy.genericLoadFailed,
    );
    final retry = retryLabel ?? ResilienceCopy.retryAction;
    final heading = title ?? (offline ? ResilienceCopy.offline : null);
    final accent = offline
        ? OraclyChrome.cream.withValues(alpha: 0.88)
        : const Color(0xFFC9A46C).withValues(alpha: 0.94);

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OraclyAsyncEmblem(
          kind: kind,
          size: compact ? 72 : 96,
          offline: offline,
          amber: !offline,
        ),
        SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
        if (heading != null) ...[
          Text(
            heading,
            textAlign: TextAlign.center,
            style: ReadingTypography.title(color: accent),
          ),
          SizedBox(height: AppSpacing.sm),
        ],
        Text(
          body,
          textAlign: TextAlign.center,
          style: ReadingTypography.body(
            color: OraclyChrome.cream.withValues(alpha: 0.82),
          ),
        ),
        if (onRetry != null) ...[
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          Semantics(
            button: true,
            label: retry,
            child: PremiumButton(
              label: retry,
              onPressed: onRetry,
              variant: PremiumButtonVariant.primary,
            ),
          ),
        ],
        if (secondaryLabel != null && onSecondary != null) ...[
          SizedBox(height: AppSpacing.sm),
          OraclyTextAction(
            label: secondaryLabel!,
            onPressed: onSecondary,
          ),
        ],
      ],
    );

    return Center(
      child: Padding(
        padding: compact
            ? EdgeInsets.symmetric(horizontal: AppSpacing.lg)
            : AppSpacing.screenHorizontal,
        child: column,
      ),
    );
  }
}
