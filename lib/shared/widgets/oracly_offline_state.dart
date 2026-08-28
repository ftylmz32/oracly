/// Offline recovery — same universe as error, quieter cream ring.
library;

import 'package:flutter/material.dart';

import '../../core/copy/resilience_copy.dart';
import '../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import 'oracly_error_state.dart';

class OraclyOfflineState extends StatelessWidget {
  const OraclyOfflineState({
    super.key,
    this.message,
    this.onRetry,
    this.kind = OraclyLoadingKind.chamber,
    this.compact = false,
    this.retryLabel,
  });

  final String? message;
  final VoidCallback? onRetry;
  final OraclyLoadingKind kind;
  final bool compact;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return OraclyErrorState(
      kind: kind,
      offline: true,
      compact: compact,
      message: message ?? ResilienceCopy.offline,
      onRetry: onRetry,
      retryLabel: retryLabel,
    );
  }
}
