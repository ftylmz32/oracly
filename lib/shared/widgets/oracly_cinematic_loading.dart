/// EPIC-025 — Cinematic loading presence via global loading cinema.
library;

import 'package:flutter/material.dart';

import '../../core/copy/resilience_copy.dart';
import '../../core/design_system/loading_cinema/oracly_loading_cinema.dart';
import '../../core/design_system/loading_cinema/oracly_loading_kind.dart';

/// Full-screen or inline cinematic loading — never a raw spinner.
class OraclyCinematicLoading extends StatelessWidget {
  const OraclyCinematicLoading({
    super.key,
    this.message,
    this.compact = false,
    this.useHeroOrb = false,
    this.onRetry,
  });

  final String? message;
  final bool compact;
  final bool useHeroOrb;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return OraclyLoadingCinema(
      kind: useHeroOrb
          ? OraclyLoadingKind.orPresence
          : OraclyLoadingKind.chamber,
      message: (message == null || message!.isEmpty)
          ? ResilienceCopy.genericLoading
          : message!,
      compact: compact,
      onRetry: onRetry,
    );
  }
}
