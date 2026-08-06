/// OR-1140 — Tarot interpretation module.
library;

import '../models/tarot_reading.dart';
import 'rule_driven_interpreter.dart';

class TarotInterpreter extends RuleDrivenInterpreter<TarotReading> {
  TarotInterpreter({required super.ruleEngine, super.copyResolver});

  @override
  String get engineId => 'tarot';

  @override
  Map<String, dynamic> buildFacts(TarotReading reading) {
    final facts = reading.toFacts();
    if (reading.cards.any((c) => c.isReversed)) {
      facts['reversed'] = reading.cards
          .where((c) => c.isReversed)
          .map((c) => c.cardId)
          .toList();
    }
    return facts;
  }
}
