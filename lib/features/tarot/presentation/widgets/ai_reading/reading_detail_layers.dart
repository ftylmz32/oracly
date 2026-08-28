/// Expandable detail layers — emotions, career, inner world, message.
library;

import 'package:flutter/material.dart';

import '../../../../../core/reading_ux/reading_expand_section.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../copy/tarot_polish_copy.dart';
import 'ai_reading_content.dart';

class ReadingDetailLayers extends StatelessWidget {
  const ReadingDetailLayers({super.key, required this.content});

  final AiReadingContent content;

  @override
  Widget build(BuildContext context) {
    final layers = <(String, String)>[
      if (content.love.trim().isNotEmpty)
        (TarotPolishCopy.emotionsTitle, content.love),
      if (content.career.trim().isNotEmpty)
        (TarotPolishCopy.careerTitle, content.career),
      if (content.spiritualGuidance.trim().isNotEmpty)
        (TarotPolishCopy.innerWorldTitle, content.spiritualGuidance),
      if (content.money.trim().isNotEmpty)
        (TarotPolishCopy.yourMessageTitle, content.money),
    ];
    if (layers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < layers.length; i++) ...[
          if (i > 0) SizedBox(height: AppSpacing.sm),
          ReadingExpandSection(title: layers[i].$1, body: layers[i].$2),
        ],
      ],
    );
  }
}
