import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';

void main() {
  group('NarrativeQuestionGrounding', () {
    test('decision mapping (TR)', () {
      final g = NarrativeQuestionGrounding.from(
        rawQuestion: 'Bu işi bırakmalı mıyım?',
      );
      expect(g.kind, QuestionKind.decision);
      expect(g.hasRealQuestion, isTrue);
      expect(g.rawText, 'Bu işi bırakmalı mıyım?');
    });

    test('relationship mapping (EN)', () {
      final g = NarrativeQuestionGrounding.from(
        rawQuestion: 'Where is this relationship going?',
      );
      expect(g.kind, QuestionKind.relationship);
      expect(g.hasRealQuestion, isTrue);
      expect(g.rawText, isNotNull);
    });

    test('guidance mapping (RU)', () {
      final g = NarrativeQuestionGrounding.from(
        rawQuestion: 'На что мне смотреть впереди?',
      );
      expect(g.kind, QuestionKind.guidance);
      expect(g.hasRealQuestion, isTrue);
      expect(g.rawText, isNotNull);
    });

    test('other → open', () {
      final g = NarrativeQuestionGrounding.from(
        rawQuestion: 'What do the cards show today?',
      );
      expect(g.kind, QuestionKind.open);
      expect(g.hasRealQuestion, isTrue);
      expect(g.rawText, isNotNull);
    });

    test('generic guidance → open + rawText null + hasRealQuestion false', () {
      final g = NarrativeQuestionGrounding.from(
        rawQuestion: 'general guidance',
      );
      expect(g.kind, QuestionKind.open);
      expect(g.rawText, isNull);
      expect(g.hasRealQuestion, isFalse);
    });

    test('empty → open', () {
      final g = NarrativeQuestionGrounding.from(rawQuestion: '');
      expect(g.kind, QuestionKind.open);
      expect(g.rawText, isNull);
      expect(g.hasRealQuestion, isFalse);
    });

    test('null → open', () {
      final g = NarrativeQuestionGrounding.from();
      expect(g.kind, QuestionKind.open);
      expect(g.rawText, isNull);
      expect(g.hasRealQuestion, isFalse);
    });

    test('sanitization preserved through ReadingQuestion.real', () {
      final g = NarrativeQuestionGrounding.from(
        rawQuestion: '  Should I leave this job?  ',
      );
      expect(g.kind, QuestionKind.decision);
      expect(g.rawText, 'Should I leave this job?');
      expect(g.hasRealQuestion, isTrue);
    });

    test('topic trim', () {
      final g = NarrativeQuestionGrounding.from(
        rawQuestion: 'Should I stay?',
        topic: '  career  ',
      );
      expect(g.topic, 'career');
    });

    test('empty topic → null', () {
      final g = NarrativeQuestionGrounding.from(
        rawQuestion: 'Should I stay?',
        topic: '   ',
      );
      expect(g.topic, isNull);
    });

    test('TR generic genel rehberlik → no real question', () {
      final g = NarrativeQuestionGrounding.from(rawQuestion: 'genel rehberlik');
      expect(g.kind, QuestionKind.open);
      expect(g.rawText, isNull);
      expect(g.hasRealQuestion, isFalse);
    });
  });
}
