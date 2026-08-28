/// Compact OR send failure — cinematic notice, gold retry, no Material red.
library;

import 'package:flutter/material.dart';

import '../../../../features/companion/copy/companion_copy.dart';
import '../../../../core/security/ai_error_sanitizer.dart';
import '../../../../shared/widgets/oracly_error_state.dart';

class OracleSendErrorBanner extends StatelessWidget {
  const OracleSendErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return OraclyErrorState(
      compact: true,
      message: AiErrorSanitizer.guard(
        message,
        fallback: CompanionCopy.connectionError,
      ),
      onRetry: onRetry,
      retryLabel: CompanionCopy.retry,
    );
  }
}
