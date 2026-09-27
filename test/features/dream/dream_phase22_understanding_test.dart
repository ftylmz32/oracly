/// Dream Phase 2.2 — understanding never observes a look-alike word.
/// Real DreamUnderstandingService.build; synthetic narratives only.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/text/turkish_lexical_matcher.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/services/dream_understanding_service.dart';

final _service = DreamUnderstandingService();

List<String> observed(String narrative, {String? language}) {
  final u = _service.build(narrative: narrative, language: language);
  return [
    ...u.symbols.map((s) => s.label),
    ...u.symbols.map((s) => s.token),
    ...u.locations,
    ...u.relationships.map((r) => r.label),
    ...u.emotions,
  ].map(TurkishLexicalMatcher.normalize).toList();
}

void main() {
  const trFalse = [
    'Bir sunum yaptım.',
    'Dün çok yemek yedim.',
    'Evren çok büyüktü.',
    'İşaret yanıp sönüyordu.',
    'Ayrıca dışarı çıktım.',
    'Ateş yükseldi.',
  ];

  test('TR look-alikes yield no symbol, place, person or feeling', () {
    const forbidden = ['su', 'yedi', 'ev', 'iş', 'iş yeri', 'ay', 'at'];
    for (final language in [null, 'tr']) {
      for (final text in trFalse) {
        final seen = observed(text, language: language);
        for (final token in forbidden) {
          expect(seen, isNot(contains(token)), reason: '$token ← "$text"');
        }
      }
    }
    expect(observed('Ateş yükseldi.', language: 'tr'), contains('ateş'));
  });

  test('audit tokens: eş, kuş, dua, huzur, anne, deniz, kapı', () {
    const cases = {
      'Eşik ve eşek gördüm.': ['eş'],
      'İçimde bir kuşku vardı, duvar soğuktu.': ['kuş', 'dua'],
      'Huzursuz uyandım.': ['huzur'],
      'Anneanneme gittim, kapıcı bekliyordu.': ['anne', 'kapı'],
      'Denizli otobüsüne bindim.': ['deniz'],
    };
    cases.forEach((text, tokens) {
      final seen = observed(text, language: 'tr');
      for (final t in tokens) {
        expect(seen, isNot(contains(t)), reason: '$t ← "$text"');
      }
    });
  });

  test('TR inflected mentions are still observed', () {
    const cases = {
      'Evdeydim.': 'ev',
      'Kapıyı açtım.': 'kapı',
      'Denizde yüzüyordum.': 'deniz',
      'Bir kedi gördüm.': 'kedi',
      'Suya baktım.': 'su',
      'Ayı gördüm.': 'ay',
      'Yediyi gördüm.': 'yedi',
    };
    cases.forEach((text, token) {
      expect(observed(text, language: 'tr'), contains(token), reason: text);
    });
    expect(_service.build(narrative: 'Evdeydim.', language: 'tr').locations,
        contains('Ev'));
  });

  test('EN look-alikes are not catalogue symbols; real words are', () {
    DreamUnderstanding en(String t) => _service.build(narrative: t, language: 'en');
    Set<String> tokens(String t) => en(t).symbols.map((s) => s.token).toSet();
    expect(tokens('I had to reduce it.'), isNot(contains('red')));
    expect(tokens('It was a long season.'), isNot(contains('sea')));
    expect(tokens('I read a catalogue.'), isNot(contains('cat')));
    expect(tokens('A red wall stood there.'), contains('red'));
    expect(tokens('I saw the sea.'), contains('sea'));
    expect(tokens('Two cats slept; one cat woke.'), contains('cat'));
  });

  test('EN narrative never runs the Turkish lexicon ("at night")', () {
    final u = _service.build(
      narrative: 'I walked along the beach at night and ate an apple.',
      language: 'en',
    );
    expect(u.symbols.map((s) => s.token), isNot(contains('at')));
    expect(u.locations, isEmpty);
    expect(u.relationships, isEmpty);
  });

  test('RU claims no catalogue and no Turkish lexicon', () {
    final u = _service.build(
      narrative: 'Мне снилось море, кот и красная дверь.',
      language: 'ru',
    );
    expect(u.symbols, isEmpty);
    expect(u.locations, isEmpty);
  });
}
