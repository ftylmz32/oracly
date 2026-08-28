/// Coffee analysis failure — cinematic recovery, never technical text.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/l10n/l10n_keys.dart';
import '../../../../core/security/ai_error_sanitizer.dart';
import '../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../../shared/widgets/oracly_error_state.dart';
import '../../copy/coffee_copy.dart';

class CoffeeErrorView extends StatelessWidget {
  const CoffeeErrorView({
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
      kind: OraclyLoadingKind.coffee,
      message: AiErrorSanitizer.guard(
        message,
        fallback: CoffeeCopy.analysisFailed,
      ),
      onRetry: onRetry,
      retryLabel: CoffeeCopy.retry,
      secondaryLabel: OraclyL10n.t(L10nKeys.back),
      onSecondary: onBack,
    );
  }
}
