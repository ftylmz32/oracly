import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n_triple.dart';
import 'package:oracly_new/features/tarot/narrative/data/profiles/narrative_major_00.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_card_profile.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_orientation_profile.dart';
import 'package:oracly_new/features/tarot/narrative/domain/reversed_transform_kind.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_profile_slice.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';

void main() {
  final profile = kNarrativeMajor00;

  void expectBase(TarotNarrativeProfileSlice slice, {required bool reversed}) {
    expect(slice.coreMeaning, same(profile.coreMeaning));
    final ori = reversed ? profile.reversed : profile.upright;
    expect(slice.orientationExpression, same(ori.expression));
    expect(slice.keywordIds, ori.keywordIds);
    expect(slice.symbolTags, profile.symbolTags);
    if (reversed) {
      expect(slice.transforms, profile.reversed.transforms);
    } else {
      expect(slice.transforms, isEmpty);
    }
  }

  group('TarotNarrativeProfileSlice matrix', () {
    test('open upright', () {
      final s = TarotNarrativeProfileSlice.fromProfile(
        profile,
        isReversed: false,
        questionKind: QuestionKind.open,
      );
      expectBase(s, reversed: false);
      expect(s.light, same(profile.light));
      expect(s.shadow, same(profile.shadow));
      expect(s.tension, same(profile.tension));
      expect(s.desire, isNull);
      expect(s.fear, isNull);
      expect(s.relationshipDynamic, isNull);
      expect(s.decisionDynamic, isNull);
      expect(s.actionDirection, isNull);
    });

    test('open reversed', () {
      final s = TarotNarrativeProfileSlice.fromProfile(
        profile,
        isReversed: true,
        questionKind: QuestionKind.open,
      );
      expectBase(s, reversed: true);
      expect(s.light, same(profile.light));
      expect(s.shadow, same(profile.shadow));
      expect(s.tension, same(profile.tension));
      expect(s.desire, isNull);
      expect(s.fear, isNull);
      expect(s.relationshipDynamic, isNull);
      expect(s.decisionDynamic, isNull);
      expect(s.actionDirection, isNull);
    });

    test('guidance upright', () {
      final s = TarotNarrativeProfileSlice.fromProfile(
        profile,
        isReversed: false,
        questionKind: QuestionKind.guidance,
      );
      expectBase(s, reversed: false);
      expect(s.light, same(profile.light));
      expect(s.shadow, same(profile.shadow));
      expect(s.tension, same(profile.tension));
      expect(s.actionDirection, same(profile.actionDirection));
      expect(s.desire, isNull);
      expect(s.fear, isNull);
      expect(s.relationshipDynamic, isNull);
      expect(s.decisionDynamic, isNull);
    });

    test('guidance reversed', () {
      final s = TarotNarrativeProfileSlice.fromProfile(
        profile,
        isReversed: true,
        questionKind: QuestionKind.guidance,
      );
      expectBase(s, reversed: true);
      expect(s.actionDirection, same(profile.actionDirection));
      expect(s.desire, isNull);
      expect(s.fear, isNull);
      expect(s.relationshipDynamic, isNull);
      expect(s.decisionDynamic, isNull);
    });

    test('relationship upright', () {
      final s = TarotNarrativeProfileSlice.fromProfile(
        profile,
        isReversed: false,
        questionKind: QuestionKind.relationship,
      );
      expectBase(s, reversed: false);
      expect(s.relationshipDynamic, same(profile.relationshipDynamic));
      expect(s.desire, same(profile.desire));
      expect(s.fear, same(profile.fear));
      expect(s.tension, same(profile.tension));
      expect(s.light, isNull);
      expect(s.shadow, isNull);
      expect(s.decisionDynamic, isNull);
      expect(s.actionDirection, isNull);
    });

    test('relationship reversed', () {
      final s = TarotNarrativeProfileSlice.fromProfile(
        profile,
        isReversed: true,
        questionKind: QuestionKind.relationship,
      );
      expectBase(s, reversed: true);
      expect(s.relationshipDynamic, same(profile.relationshipDynamic));
      expect(s.light, isNull);
      expect(s.shadow, isNull);
      expect(s.decisionDynamic, isNull);
      expect(s.actionDirection, isNull);
    });

    test('decision upright', () {
      final s = TarotNarrativeProfileSlice.fromProfile(
        profile,
        isReversed: false,
        questionKind: QuestionKind.decision,
      );
      expectBase(s, reversed: false);
      expect(s.decisionDynamic, same(profile.decisionDynamic));
      expect(s.actionDirection, same(profile.actionDirection));
      expect(s.tension, same(profile.tension));
      expect(s.fear, same(profile.fear));
      expect(s.light, isNull);
      expect(s.shadow, isNull);
      expect(s.desire, isNull);
      expect(s.relationshipDynamic, isNull);
    });

    test('decision reversed', () {
      final s = TarotNarrativeProfileSlice.fromProfile(
        profile,
        isReversed: true,
        questionKind: QuestionKind.decision,
      );
      expectBase(s, reversed: true);
      expect(s.decisionDynamic, same(profile.decisionDynamic));
      expect(s.light, isNull);
      expect(s.shadow, isNull);
      expect(s.desire, isNull);
      expect(s.relationshipDynamic, isNull);
    });

    test('source profile unchanged + slice lists isolated', () {
      final keywords = <String>['a', 'b'];
      final symbols = <String>['s1'];
      final transforms = <ReversedTransformKind>[ReversedTransformKind.delay];
      final mutable = NarrativeCardProfile(
        canonicalCardId: 'test_mut',
        coreMeaning: const L10nTriple('t', 'e', 'r'),
        light: const L10nTriple('t', 'e', 'r'),
        shadow: const L10nTriple('t', 'e', 'r'),
        tension: const L10nTriple('t', 'e', 'r'),
        desire: const L10nTriple('t', 'e', 'r'),
        fear: const L10nTriple('t', 'e', 'r'),
        relationshipDynamic: const L10nTriple('t', 'e', 'r'),
        decisionDynamic: const L10nTriple('t', 'e', 'r'),
        actionDirection: const L10nTriple('t', 'e', 'r'),
        upright: NarrativeOrientationProfile(
          expression: const L10nTriple('t', 'e', 'r'),
          transforms: const [],
          keywordIds: keywords,
        ),
        reversed: NarrativeOrientationProfile(
          expression: const L10nTriple('t', 'e', 'r'),
          transforms: transforms,
          keywordIds: keywords,
        ),
        symbolTags: symbols,
        profileRevision: 1,
      );

      final slice = TarotNarrativeProfileSlice.fromProfile(
        mutable,
        isReversed: true,
        questionKind: QuestionKind.open,
      );

      expect(() => slice.keywordIds.add('x'), throwsUnsupportedError);
      expect(() => slice.symbolTags.add('x'), throwsUnsupportedError);
      expect(
        () => slice.transforms.add(ReversedTransformKind.excess),
        throwsUnsupportedError,
      );

      keywords.add('injected');
      symbols.add('injected');
      transforms.add(ReversedTransformKind.excess);

      expect(slice.keywordIds, ['a', 'b']);
      expect(slice.symbolTags, ['s1']);
      expect(slice.transforms, [ReversedTransformKind.delay]);
      expect(mutable.upright.keywordIds, contains('injected'));
      expect(mutable.symbolTags, contains('injected'));
    });
  });
}
