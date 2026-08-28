/// Final coffee fortune engine — 10 provider-backed cups, one spoken reading.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/fortune_voice.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading/human_reader.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_symbol.dart';
import 'package:oracly_new/features/coffee/services/coffee_fortune_composer.dart';
import 'package:oracly_new/features/coffee/services/coffee_fortune_narration.dart';

import 'coffee_fortune_engine_cups.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('ten provider-backed cups read as one fortune, not AI cards', () {
    final cups = coffeeFortuneEngineCups;
    final texts = [for (final cup in cups) _compose(cup).overall];
    expect(texts, hasLength(10));
    final openings = <String>{};
    var dictionaryHits = 0;
    for (var i = 0; i < texts.length; i++) {
      final text = texts[i];
      final lower = text.toLowerCase();
      expect(text.trim(), isNotEmpty);
      expect(text.contains('='), isFalse, reason: text);
      expect(lower, isNot(contains('kuş = ')));
      expect(lower, isNot(contains('yolculuk.')));
      expect(HumanReader.looksGeneric(text), isFalse, reason: text);
      expect(FortuneVoice.looksRobotic(text), isFalse, reason: text);
      expect(FortuneVoice.claimsCertainty(text), isFalse, reason: text);
      expect(text.contains('...'), isFalse, reason: text);
      expect(
        text.split(RegExp(r'[.!?]+')).where((p) => p.trim().isNotEmpty).length,
        greaterThanOrEqualTo(2),
        reason: text,
      );
      openings.add(text.split('.').first.trim());
      for (final name in cups[i].symbols) {
        expect(lower, contains(name.toLowerCase()), reason: text);
      }
      if (cups[i].symbols.length >= 2) {
        expect(
          lower.contains('birlikte') ||
              lower.contains('yanındaki') ||
              lower.contains('yanında') ||
              lower.contains('yan yana'),
          isTrue,
          reason: text,
        );
      }
      if (RegExp(r'^(burada|bu |şurada)\b').hasMatch(lower)) {
        dictionaryHits++;
      }
    }
    expect(openings.length, greaterThanOrEqualTo(5));
    expect(texts.toSet().length, greaterThanOrEqualTo(8));
    // Openings should not all start with the same stock deictic.
    expect(dictionaryHits, lessThan(texts.length));
  });

  test('vision dump of card-equations is rewritten and faint stays faint', () {
    final birdRoad = _compose(coffeeFortuneEngineCups.first);
    expect(birdRoad.overall.toLowerCase(), contains('haber'));
    expect(birdRoad.money, isEmpty);
    expect(birdRoad.love, isEmpty);
    final spoken = CoffeeFortuneNarration.body(birdRoad);
    expect(spoken, contains(birdRoad.overall));
    expect(spoken, isNot(contains('Kuş = haber')));
    final faint = CoffeeFortuneComposer.compose(
      CoffeeReading(
        id: 'faint-only',
        createdAt: DateTime(2026, 8, 18),
        overall: 'Kuş = haber.',
        love: '',
        career: '',
        money: '',
        nearFuture: '',
        takeaway: '',
        visualObservation: 'Ağızda belirsiz bir iz.',
        symbols: const [
          CoffeeSymbol(
            name: 'kuş',
            meaning: '',
            interpretation: '',
            trust: CoffeeMarkTrust.low,
          ),
        ],
      ),
    );
    expect(faint.overall.toLowerCase(), contains('net değil'));
    expect(faint.overall.toLowerCase(), contains('kuş'));
    expect(faint.overall, isNot(contains('=')));
  });
}

CoffeeReading _compose(CoffeeFortuneEngineCup cup) {
  return CoffeeFortuneComposer.compose(
    CoffeeReading(
      id: cup.id,
      createdAt: DateTime(2026, 8, 18),
      overall: cup.overall,
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: '',
      visualObservation: cup.observation,
      symbols: [
        for (final name in cup.symbols)
          CoffeeSymbol(
            name: name,
            meaning: '',
            interpretation: '',
            trust: cup.trust,
          ),
      ],
    ),
    themes: cup.themes,
  );
}
