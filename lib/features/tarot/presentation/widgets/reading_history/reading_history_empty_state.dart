/// OR-1070 — Empty journal state.
library;

import 'package:flutter/material.dart';

import '../../../../../shared/widgets/oracly_empty_state.dart';

class ReadingHistoryEmptyState extends StatelessWidget {
  const ReadingHistoryEmptyState({
    super.key,
    this.onStartReading,
  });

  final VoidCallback? onStartReading;

  static const String message =
      'Henüz kayıtlı bir açılım yok. İlk kartını çektiğinde burada birikecek.';

  @override
  Widget build(BuildContext context) {
    return OraclyEmptyState(
      icon: Icons.auto_stories_rounded,
      message: message,
      ctaLabel: onStartReading != null ? 'İlk kartını çek' : null,
      onCta: onStartReading,
    );
  }
}
