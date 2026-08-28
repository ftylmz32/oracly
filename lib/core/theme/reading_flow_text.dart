/// Paragraph pacing for slow, calm reading — one implementation.
library;

import 'package:flutter/material.dart';

import 'craftsmanship_rhythm.dart';

/// Renders body copy with gentle paragraph breaks — never a wall of text.
class ReadingFlowText extends StatelessWidget {
  const ReadingFlowText({
    super.key,
    required this.text,
    required this.style,
    this.emphasizeFirst = false,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle style;
  final bool emphasizeFirst;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final paragraphs = paragraphsOf(text.trim());
    if (paragraphs.length <= 1) {
      return Text(
        paragraphs.first,
        textAlign: textAlign,
        style: style,
        softWrap: true,
        overflow: TextOverflow.visible,
      );
    }

    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) SizedBox(height: CraftsmanshipRhythm.paragraphGap),
          Text(
            paragraphs[i],
            textAlign: textAlign,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: i == 0 && emphasizeFirst
                ? style.copyWith(fontWeight: FontWeight.w500)
                : style,
          ),
        ],
      ],
    );
  }

  @visibleForTesting
  static List<String> debugParagraphs(String raw) => paragraphsOf(raw);

  static List<String> paragraphsOf(String raw) {
    if (raw.isEmpty) return const [''];

    final explicit = raw
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (explicit.length > 1) return explicit;

    final sentences = _splitSentences(raw);
    if (sentences.length <= 2) return [raw];

    final grouped = <String>[];
    final buffer = StringBuffer();
    for (var i = 0; i < sentences.length; i++) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(sentences[i]);
      final isPair = (i + 1) % 2 == 0;
      final isLast = i == sentences.length - 1;
      if (isPair || isLast) {
        grouped.add(buffer.toString().trim());
        buffer.clear();
      }
    }
    return grouped.isEmpty ? [raw] : grouped;
  }

  static List<String> _splitSentences(String text) {
    final matches = RegExp(r'[^.!?…]+[.!?…]?').allMatches(text);
    return matches
        .map((m) => m.group(0)?.trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

String readingCompleteSentence(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.endsWith('…')) return trimmed;
  if (trimmed.endsWith('.') ||
      trimmed.endsWith('!') ||
      trimmed.endsWith('?')) {
    return trimmed;
  }
  return '$trimmed.';
}
