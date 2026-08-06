/// OR-1140 — Generic engine output envelope.
library;

import 'oracle_engine_type.dart';

class OracleResult<T> {
  const OracleResult({
    required this.engine,
    required this.readingId,
    required this.payload,
    required this.sections,
    required this.generatedAt,
    this.ruleSetId,
  });

  final OracleEngineType engine;
  final String readingId;
  final T payload;
  final List<InterpretationSection> sections;
  final DateTime generatedAt;
  final String? ruleSetId;
}

class InterpretationSection {
  const InterpretationSection({
    required this.key,
    required this.title,
    required this.content,
    this.weight = 1,
    this.tags = const [],
  });

  final String key;
  final String title;
  final String content;
  final int weight;
  final List<String> tags;
}
