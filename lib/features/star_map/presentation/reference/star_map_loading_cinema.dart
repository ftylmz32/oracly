/// Yıldızname quiet wait — archive atmosphere, never natal spinner.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/loading_cinema/oracly_loading_cinema.dart';
import '../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../../core/copy/resilience_copy.dart';

class StarMapLoadingCinema extends StatelessWidget {
  const StarMapLoadingCinema({
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
    return OraclyLoadingCinema(
      kind: OraclyLoadingKind.yildizname,
      message: message ?? ResilienceCopy.genericLoading,
      onRetry: onRetry,
      compact: compact,
    );
  }
}
