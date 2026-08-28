/// Palm analysis failure — cinematic recovery, never technical text.
library;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../core/security/ai_error_sanitizer.dart';
import '../../../shared/widgets/oracly_error_state.dart';
import '../copy/palm_copy.dart';

class PalmErrorView extends StatelessWidget {
  const PalmErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onBack,
    this.canRetrySameImage = false,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final bool canRetrySameImage;

  @override
  Widget build(BuildContext context) {
    return OraclyErrorState(
      kind: OraclyLoadingKind.chamber,
      message: AiErrorSanitizer.guard(
        message,
        fallback: PalmCopy.analysisFailed,
      ),
      onRetry: onRetry,
      retryLabel:
          canRetrySameImage ? PalmCopy.retryAnalysis : PalmCopy.chooseAnotherPhoto,
      secondaryLabel: OraclyL10n.t(L10nKeys.back),
      onSecondary: onBack,
    );
  }
}
