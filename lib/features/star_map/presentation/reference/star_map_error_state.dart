/// Yıldızname recoverable error — archive atmosphere, never Material red.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../../shared/widgets/oracly_error_state.dart';

class StarMapErrorState extends StatelessWidget {
  const StarMapErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OraclyErrorState(
      kind: OraclyLoadingKind.yildizname,
      message: message,
      onRetry: onRetry,
      compact: compact,
    );
  }
}
