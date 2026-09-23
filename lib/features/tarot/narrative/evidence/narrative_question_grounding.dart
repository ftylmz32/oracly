/// Narrative Evidence — question kinds and grounding (Phase 3D.1A).
library;

import '../../reading/reading_ask.dart';
import '../../reading/reading_question.dart';

enum QuestionKind { decision, relationship, guidance, open }

class QuestionGrounding {
  const QuestionGrounding({
    required this.rawText,
    required this.topic,
    required this.kind,
    required this.hasRealQuestion,
  });

  /// Sanitized real question text, or null when [ReadingQuestion.real] is null.
  final String? rawText;
  final String? topic;
  final QuestionKind kind;
  final bool hasRealQuestion;
}

abstract final class NarrativeQuestionGrounding {
  NarrativeQuestionGrounding._();

  static QuestionGrounding from({String? rawQuestion, String? topic}) {
    final real = ReadingQuestion.real(rawQuestion);
    final askKind = ReadingAsk.kind(rawQuestion);
    return QuestionGrounding(
      rawText: real,
      topic: _normalizeTopic(topic),
      kind: _mapKind(askKind),
      hasRealQuestion: real != null,
    );
  }

  static QuestionKind _mapKind(ReadingAskKind ask) => switch (ask) {
    ReadingAskKind.decision => QuestionKind.decision,
    ReadingAskKind.relationship => QuestionKind.relationship,
    ReadingAskKind.guidance => QuestionKind.guidance,
    ReadingAskKind.other => QuestionKind.open,
  };

  static String? _normalizeTopic(String? topic) {
    final t = topic?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }
}
