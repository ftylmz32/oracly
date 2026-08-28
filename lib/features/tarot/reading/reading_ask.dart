/// What the user is actually asking — the spine of the reading.
library;

import 'reading_question.dart';

enum ReadingAskKind { decision, relationship, guidance, other }

abstract final class ReadingAsk {
  ReadingAsk._();

  static ReadingAskKind kind(String? raw) {
    final q = (ReadingQuestion.real(raw) ?? '').toLowerCase();
    if (q.isEmpty) return ReadingAskKind.other;
    if (_any(q, _decision)) return ReadingAskKind.decision;
    if (_any(q, _relation)) return ReadingAskKind.relationship;
    if (_any(q, _guidance)) return ReadingAskKind.guidance;
    return ReadingAskKind.other;
  }

  static String leadKey(String? raw) =>
      'tarot.ask.lead.${kind(raw).name}';

  static String closeKey(String? raw) =>
      'tarot.ask.close.${kind(raw).name}';

  static bool _any(String hay, List<String> needles) =>
      needles.any(hay.contains);

  static const _decision = [
    'bırakmalı',
    'bırakayım',
    'should i',
    'should we',
    'karar',
    'quit',
    'leave',
    'mıyım',
    'miyim',
    'mü müyüm',
    'стоит ли',
    'должен ли',
    'оставить',
    'бросить',
  ];

  static const _relation = [
    'ilişki',
    'niyeti',
    'niyet',
    'nereye gidiyor',
    'partner',
    'aşk',
    'sevgili',
    'relationship',
    'this person',
    'his intention',
    'her intention',
    'love',
    'отношен',
    'чувства',
    'намёрен',
    'намерен',
  ];

  static const _guidance = [
    'dikkat',
    'dönemde',
    'neye',
    'nasıl iler',
    'önümdeki',
    'what should i watch',
    'what to watch',
    'guidance',
    'на что',
    'куда смотр',
    'впереди',
  ];
}
