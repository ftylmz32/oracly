// Dream Phase 4B — client guard parity: stated feelings are not invented
// images, the reflection may lean on the safe memory, and the backend's
// catalogue mirror matches the client catalogue exactly.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/content/dream/data/dream_symbol_catalogue.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_facts.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_guard.dart';
import 'package:oracly_new/features/dream/services/dream_stated_feeling.dart';

DreamAnalysisFacts _facts(String told, String language) =>
    DreamAnalysisFacts(told: told, scene: told, language: language);

void main() {
  test('a stated or denied fear is told, not an invented image', () {
    for (final told in [
      'I felt calm, not afraid.',
      'I was scared of the dog.',
      'Hiç korkmadım, sadece merak ettim.',
    ]) {
      expect(DreamStatedFeeling.tells('dream_fear', told), isTrue, reason: told);
    }
    expect(DreamStatedFeeling.tells('dream_fear', 'A red door on a beach.'),
        isFalse);
    expect(DreamStatedFeeling.tells('dream_door', 'I was not afraid.'), isFalse);
  });

  test('"fear absent" passes only when the dreamer spoke of fear', () {
    const told =
        'I was walking along a quiet beach at night and a red door stood in the sand; I felt calm, not afraid.';
    expect(
      DreamAnalysisGuard.isSpeakable(
          'Calm curiosity on the quiet beach, with fear absent.', _facts(told, 'en')),
      isTrue,
    );
    expect(
      DreamAnalysisGuard.isSpeakable(
          'Calm curiosity on the quiet beach, with fear absent.',
          _facts('I was walking along a quiet beach at night.', 'en')),
      isFalse,
    );
  });

  test('the reflection may lean on the safe memory; nothing else does', () {
    const told = 'I dreamed of a white horse standing still.';
    const reflection =
        'Your recent context mentioned making space for something new; one small space could be enough.';
    final facts = _facts(told, 'en');
    expect(DreamAnalysisGuard.isSpeakable(reflection, facts), isFalse);
    expect(
      DreamAnalysisGuard.isSpeakable(
        reflection,
        facts.withContext('A recent reading touched on making space for something new.'),
      ),
      isTrue,
    );
    expect(identical(facts.withContext('  '), facts), isTrue);
  });

  test('backend catalogue mirror equals DreamSymbolCatalogue', () {
    final source =
        File('backend/src/ai/dream-client-parity.ts').readAsStringSync();
    final mirrored = RegExp(r"\{ id: '(\w+)', en: '([^']+)', tr: '([^']+)' \}")
        .allMatches(source)
        .map((m) => '${m[1]}|${m[2]}|${m[3]}')
        .toList();
    final client = DreamSymbolCatalogue.all
        .map((s) => '${s.id}|${s.token.toLowerCase()}|${s.tokenTr.toLowerCase()}')
        .toList();
    expect(mirrored, client);
  });
}
