/// Tarot loading — deck anticipation cinema, never a Material spinner.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/loading_cinema/oracly_loading_cinema.dart';
import '../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../core/personality/or_living_voice.dart';

class TarotLoading extends StatelessWidget {
  const TarotLoading({
    super.key,
    this.message,
    this.onRetry,
    this.compact = false,
  });

  final String? message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label =
        message ?? OrLivingVoice.thinking(surface: OrLivingSurface.tarot);
    return OraclyLoadingCinema(
      kind: OraclyLoadingKind.tarot,
      message: label,
      onRetry: onRetry,
      compact: compact,
    );
  }
}
