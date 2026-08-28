/// Tarot recoverable error — cinematic Oracly surface, never Material red.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../core/security/ai_error_sanitizer.dart';
import '../../../shared/widgets/oracly_error_state.dart';

class TarotErrorState extends StatelessWidget {
  const TarotErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return OraclyErrorState(
      kind: OraclyLoadingKind.tarot,
      message: AiErrorSanitizer.guard(message),
      onRetry: onRetry,
    );
  }
}
