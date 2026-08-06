/// OR-1140 — Astrology interpretation module.
library;

import '../models/horoscope_reading.dart';
import 'rule_driven_interpreter.dart';

class AstrologyInterpreter extends RuleDrivenInterpreter<HoroscopeReading> {
  AstrologyInterpreter({required super.ruleEngine, super.copyResolver});

  @override
  String get engineId => 'astrology';

  @override
  Map<String, dynamic> buildFacts(HoroscopeReading reading) => reading.toFacts();
}
