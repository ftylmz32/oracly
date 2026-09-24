/// Phase 6E — safety / input firewall / no live callsites.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_classical_shadow.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_status.dart';

import 'narrative_shadow_test_support.dart';

ReadingSession _withIntention(ReadingSession base, String text) {
  return ReadingSession(
    id: base.id,
    deckId: base.deckId,
    spread: base.spread,
    intention: TarotIntention(text: text, topic: base.intention.topic),
    shuffleSeed: base.shuffleSeed,
    startedAt: base.startedAt,
    drawnCards: base.drawnCards,
  );
}

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('empty session/reading before safety', () {
    final base = sessionFromEvidence(launchScenarios().first);
    final emptyId = ReadingSession(
      id: '  ',
      deckId: base.deckId,
      spread: base.spread,
      intention: const TarotIntention(text: 'Bu fal hastalığımı gösteriyor mu?'),
      shuffleSeed: 1,
      startedAt: base.startedAt,
      drawnCards: base.drawnCards,
    );
    final a = NarrativeTarotClassicalShadow.evaluate(
      session: emptyId,
      readingId: 'r',
      languageCode: 'tr',
    );
    expect(a.status, NarrativeTarotShadowStatus.invalidSession);
    expect(a.inputFailure, NarrativeTarotShadowInputFailure.emptySessionId);
    expect(a.finalNarrativeRequest, isNull);

    final b = NarrativeTarotClassicalShadow.evaluate(
      session: base,
      readingId: '',
      languageCode: 'tr',
    );
    expect(b.status, NarrativeTarotShadowStatus.invalidSession);
    expect(b.inputFailure, NarrativeTarotShadowInputFailure.emptyReadingId);
  });

  test('safetyBlocked TR/EN/RU — no Narrative candidate', () {
    final base = sessionFromEvidence(launchScenarios().first);
    final cases = <(String, String)>[
      ('tr', 'Bu fal hastalığımı gösteriyor mu?'),
      ('en', 'Will this tarot diagnose my illness?'),
      ('ru', 'Таро даст диагноз болезни?'),
    ];
    for (final c in cases) {
      OraclyL10n.bind(c.$1);
      final result = NarrativeTarotClassicalShadow.evaluate(
        session: _withIntention(base, c.$2),
        readingId: 'safety_${c.$1}',
        languageCode: c.$1,
      );
      expect(
        result.status,
        NarrativeTarotShadowStatus.safetyBlocked,
        reason: c.$1,
      );
      expect(result.finalNarrativeRequest, isNull);
      expect(result.promptInput, isNull);
      expect(result.wirePayload, isNull);
    }
  });

  test('no live production imports of narrative/shadow', () {
    final roots = [
      'lib/features/tarot/presentation',
      'lib/features/tarot/services',
      'lib/features/tarot/economy',
      'lib/features/tarot/interpretation/executors',
      'lib/features/ai',
      'lib/features/gems',
      'lib/core/services',
    ];
    final hits = <String>[];
    for (final root in roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      for (final f in dir.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        final text = f.readAsStringSync();
        if (text.contains('narrative/shadow/')) {
          hits.add(f.path);
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}
