/// RC-002 — Tone guard for AI conversation responses.
library;

import '../../insights/services/reflective_intelligence.dart';

abstract final class ConversationResponseGuard {
  ConversationResponseGuard._();

  /// Softens certainty and trims excessive length without changing structure.
  static String polish(String text) {
    final softened = ReflectiveIntelligence.soften(text.trim());
    if (softened.isEmpty) return softened;
    return _trimWallOfText(softened);
  }

  static String _trimWallOfText(String text) {
    final paragraphs = text.split(RegExp(r'\n{2,}'));
    if (paragraphs.length <= 6) return text;

    final kept = paragraphs.take(6).join('\n\n');
    return kept;
  }
}
