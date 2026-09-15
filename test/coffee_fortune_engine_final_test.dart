/// Final coffee fortune engine — 10 provider-backed cups, one spoken reading.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_symbol.dart';
import 'package:oracly_new/features/coffee/services/coffee_fortune_composer.dart';
import 'package:oracly_new/features/coffee/services/coffee_fortune_narration.dart';

import 'coffee_fortune_engine_cups.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test(
    'BATCH 3A.2: ten provider-backed cups with raw vision-dump overalls '
    'all fail composition, never surfacing an AI-card-report as a reading',
    () {
      final cups = coffeeFortuneEngineCups;
      for (final cup in cups) {
        expect(_compose(cup), isNull, reason: cup.overall);
      }
    },
  );

  test(
    'BATCH 3A.2: a vision dump of card-equations is a failure, never '
    'rewritten into a reading — faint or firm trust makes no difference',
    () {
      expect(_compose(coffeeFortuneEngineCups.first), isNull);
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
      expect(faint, isNull);
    },
  );

  test(
    'a valid backend overall still narrates cleanly through CoffeeFortuneNarration',
    () {
      final reading = CoffeeFortuneComposer.compose(
        CoffeeReading(
          id: 'valid',
          createdAt: DateTime(2026, 8, 18),
          overall:
              'Fincanda beliren yol, ertelenen bir kararın yeniden gündeme '
              'geldiğine işaret ediyor; bunu zorlamadan, kendi hızında ele '
              'almak sana iyi gelebilir.',
          love: '',
          career: '',
          money: '',
          nearFuture: '',
          takeaway: '',
          visualObservation: 'Ağızda kuş, yanında açık bir yol.',
          symbols: const [
            CoffeeSymbol(name: 'kuş', meaning: '', interpretation: ''),
          ],
        ),
      )!;
      expect(reading.money, isEmpty);
      expect(reading.love, isEmpty);
      final spoken = CoffeeFortuneNarration.body(reading);
      expect(spoken, contains(reading.overall));
      expect(spoken, isNot(contains('Kuş = haber')));
    },
  );
}

CoffeeReading? _compose(CoffeeFortuneEngineCup cup) {
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
