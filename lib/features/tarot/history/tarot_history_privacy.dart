/// What a completed tarot reading may keep — never extra private raw text.
library;

import '../../../core/domain/models/reading.dart';
import '../../discovery_share/services/discovery_share_sanitize.dart';
import '../reading/reading_question.dart';

abstract final class TarotHistoryPrivacy {
  TarotHistoryPrivacy._();

  static const maxQuestionSummary = 56;

  /// Real asked question, clipped. Generic / leaking text is dropped.
  static String? questionSummary(String? raw) {
    final real = ReadingQuestion.real(raw);
    if (real == null) return null;
    if (DiscoveryShareSanitize.leaksPrivate(real)) return null;
    return _clip(real, maxQuestionSummary);
  }

  /// Topic label only — never the question itself.
  static String? persistTopic(String? topic, String? question) {
    final t = topic?.trim() ?? '';
    if (t.isEmpty) return null;
    if (t == question?.trim()) return null;
    final looksAsked = ReadingQuestion.real(t) != null &&
        (t.contains('?') || t.length > 24);
    if (looksAsked) return null;
    return t;
  }

  static String spreadTitle(String spreadType) {
    final raw = spreadType.trim();
    return switch (raw) {
      'Tek Kart' => '1 Kart Açılımı',
      'Üç Kart' || 'Üç Kart Açılımı' => '3 Kart Açılımı',
      'Beş Kart' => '5 Kart Açılımı',
      'Yedi Kart' || 'Seven card' || 'Seven Card' => '7 Kart Açılımı',
      'Kelt Haçı' || 'Celtic Cross' => 'Kelt Haçı',
      _ => raw.isEmpty ? 'Tarot' : raw,
    };
  }

  static String shortInsight(ReadingModel reading) {
    final excerpt = reading.summaryExcerpt?.trim();
    if (excerpt != null && excerpt.isNotEmpty) return excerpt;
    return _clip(reading.aiSummary, 140);
  }

  static String _clip(String raw, int max) {
    final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= max) return text;
    final cut = text.substring(0, max);
    final last = cut.lastIndexOf(' ');
    final base = last > max ~/ 2 ? cut.substring(0, last) : cut;
    return '$base…';
  }
}
