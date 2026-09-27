/// Recurring-thread card — shown only when saved Dreams back it.
library;

import 'package:flutter/material.dart';

import '../../models/dream.dart';
import '../../models/dream_insight.dart';
import '../../services/dream_reading_presentation.dart';
import 'dream_result_premium_card.dart';

class DreamResultHistoryCard extends StatelessWidget {
  const DreamResultHistoryCard({super.key, required this.dream});

  final Dream dream;

  @override
  Widget build(BuildContext context) {
    final insight = DreamReadingPresentation.insightOf(
      dream,
      DreamInsightKind.recurringPattern,
    );
    final title = insight?.title?.trim() ?? '';
    if (insight == null || title.isEmpty) return const SizedBox.shrink();
    return DreamResultPremiumCard(
      title: title,
      body: insight.body.trim(),
      icon: Icons.history_rounded,
    );
  }
}
