/// OR-1140 — Daily energy interpretation module.
library;

import '../models/energy_reading.dart';
import 'rule_driven_interpreter.dart';

class EnergyInterpreter extends RuleDrivenInterpreter<EnergyReading> {
  EnergyInterpreter({required super.ruleEngine, super.copyResolver});

  @override
  String get engineId => 'dailyEnergy';

  @override
  Map<String, dynamic> buildFacts(EnergyReading reading) => reading.toFacts();
}
