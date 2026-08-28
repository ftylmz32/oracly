/// Observation → connection → interpretation → personal relevance.
library;

import '../copy/fortune_voice.dart';
import 'human_reader_guard.dart';
import 'human_reader_notice.dart';
import 'human_reader_phrases.dart';

abstract final class HumanReaderCompose {
  HumanReaderCompose._();

  static String build(HumanReaderNotice notice) {
    if (!notice.hasSeen && !notice.hasMeaning && !notice.hasEvidence) {
      return '';
    }
    final parts = <String>[];
    if (notice.hasSeen) {
      parts.add(HumanReaderPhrases.see(notice));
    }
    if (notice.hasCompanion && !_same(notice.companion, notice.seen)) {
      parts.add(HumanReaderPhrases.link(notice));
    }
    if (notice.hasMeaning && !_same(notice.meaning, notice.seen)) {
      parts.add(HumanReaderGuard.scrub(notice.meaning));
    }
    if (notice.hasEvidence &&
        (notice.length == HumanReaderLength.deep || parts.length < 3)) {
      parts.add(HumanReaderGuard.scrub(notice.evidence));
    }
    if (notice.hasLife) {
      parts.add(HumanReaderPhrases.you(notice));
    }
    if (notice.length == HumanReaderLength.deep) {
      parts.add(HumanReaderPhrases.hedge(notice));
    }
    final max = notice.length == HumanReaderLength.deep ? 10 : 5;
    return _cap(FortuneVoice.joinSentences(parts, max: max));
  }

  static bool _same(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  static String _cap(String text) {
    return text.split('. ').map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    }).join('. ');
  }
}
