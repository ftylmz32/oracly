/// Dream's cross-feature theme suggestion must reflect only what the user
/// actually wrote in the current dream -- never a word that only appears in
/// AI-generated interpretation prose (which can be influenced by injected
/// historical memory, or use a theme word generically, e.g. "ilişki"/
/// "bağlantı" meaning "connection between symbols" rather than a romantic
/// relationship).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_result_actions.dart';

Dream _dream(String narrative) => Dream(
      id: 'd1',
      narrative: narrative,
      recordedAt: DateTime(2026, 9, 11),
    );

void main() {
  test('no dream selected yields no themes', () {
    expect(DreamReferenceResultActions.themesFor(null), isEmpty);
  });

  test('a dream narrative with no theme content yields no themes', () {
    const narrative =
        'Gece eski bir evin bahçesindeydim, gökyüzü çok açıktı ve '
        'yıldızlar normalden çok daha yakın görünüyordu. Önümde altın '
        'bir kapı belirdi ve hafif bir yağmur başladı.';
    expect(DreamReferenceResultActions.themesFor(_dream(narrative)), isEmpty);
  });

  test(
    'a theme word appearing only in generated interpretation prose is not '
    'attributed to the dream',
    () {
      // Regression for a real production defect: the old computation fed
      // [narrative, analysis] into PersonalThemeExtractor.labelsIn, so a
      // generic word in the AI's own prose (e.g. "ilişki" meaning "the
      // connection between these symbols", or a word carried over from
      // injected historical memory) could combine with an unrelated,
      // incidental match in the narrative to leak a theme -- such as
      // "ilişki" -- that has nothing to do with what the user described.
      const narrative =
          'Gece eski bir evin bahçesindeydim, gökyüzü çok açıktı ve '
          'yıldızlar normalden çok daha yakın görünüyordu.';
      final themes = DreamReferenceResultActions.themesFor(_dream(narrative));
      expect(themes, isNot(contains('ilişki')));
      expect(themes, isEmpty);
    },
  );

  test('a theme genuinely present in the narrative itself is kept', () {
    const narrative =
        'Annemle birlikte eski evin bahçesindeydik, aramızdaki bağ hiç bu '
        'kadar güçlü hissettirmemişti.';
    final themes = DreamReferenceResultActions.themesFor(_dream(narrative));
    expect(themes, contains('ilişki'));
  });
}
