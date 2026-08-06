/// OR-1140 — Dream interpretation module.
library;

import '../models/dream_reading.dart';
import 'rule_driven_interpreter.dart';

class DreamInterpreter extends RuleDrivenInterpreter<DreamReading> {
  DreamInterpreter({required super.ruleEngine, super.copyResolver});

  @override
  String get engineId => 'dream';

  @override
  Map<String, dynamic> buildFacts(DreamReading reading) => reading.toFacts();
}
