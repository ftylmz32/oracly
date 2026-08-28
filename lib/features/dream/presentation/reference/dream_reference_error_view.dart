/// Dream analysis failure — cinematic recovery, never technical text.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/l10n/l10n_keys.dart';
import '../../../../core/security/ai_error_sanitizer.dart';
import '../../../../shared/widgets/oracly_error_state.dart';
import '../../copy/dream_copy.dart';

class DreamReferenceErrorView extends StatelessWidget {
  const DreamReferenceErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return OraclyErrorState(
      message: AiErrorSanitizer.guard(
        message,
        fallback: DreamCopy.analysisFailed,
      ),
      onRetry: onRetry,
      retryLabel: DreamCopy.retry,
      secondaryLabel: OraclyL10n.t(L10nKeys.back),
      onSecondary: onBack,
    );
  }
}
