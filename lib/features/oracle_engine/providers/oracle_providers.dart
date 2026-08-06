/// OR-1140 — Riverpod providers for Oracle Engine.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine_contract.dart';
import '../core/oracle_engine_type.dart';
import '../core/oracle_result.dart';
import '../data/in_memory_oracle_reading_repository.dart';
import '../domain/oracle_reading_repository.dart';
import '../rules/rule_engine.dart';
import '../rules/rule_registry.dart';
import '../services/oracle_engine_factory.dart';
import '../services/oracle_service.dart';

// ── Infrastructure ─────────────────────────────────────────────────

final ruleEngineProvider = Provider<RuleEngine>((ref) {
  return ConfigurableRuleEngine();
});

final ruleRegistryProvider = Provider<RuleRegistry>((ref) {
  final registry = InMemoryRuleRegistry();
  OracleEngineFactory.buildRegistry(ruleRegistry: registry);
  return registry;
});

final oracleEngineRegistryProvider = Provider<OracleEngineRegistry>((ref) {
  return OracleEngineFactory.buildRegistry(
    ruleEngine: ref.watch(ruleEngineProvider),
  );
});

final oracleReadingRepositoryProvider = Provider<OracleReadingRepository>((ref) {
  return InMemoryOracleReadingRepository();
});

final oracleServiceProvider = Provider<OracleService>((ref) {
  return DefaultOracleService(
    engineRegistry: ref.watch(oracleEngineRegistryProvider),
    readingRepository: ref.watch(oracleReadingRepositoryProvider),
  );
});

// ── OracleProvider ─────────────────────────────────────────────────

final oracleProvider = Provider<OracleService>((ref) {
  return ref.watch(oracleServiceProvider);
});

// ── ReadingProvider ────────────────────────────────────────────────

/// Engine-scoped reading list from [OracleReadingRepository].
/// Distinct from app-level [readingHistoryProvider] in `app_providers.dart`.
final oracleEngineReadingsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, OracleEngineType>(
  (ref, engine) async {
    final repo = ref.watch(oracleReadingRepositoryProvider);
    return repo.listByEngine(engine);
  },
);

@Deprecated('Use oracleEngineReadingsProvider')
final readingHistoryProvider = oracleEngineReadingsProvider;

// ── InterpretationProvider ─────────────────────────────────────────

final interpretationProvider = FutureProvider.family<
    List<InterpretationSection>,
    ({OracleEngineType engine, dynamic input})>(
  (ref, params) async {
    final service = ref.watch(oracleServiceProvider);
    final result = await service.run(
      engine: params.engine,
      input: params.input,
    );
    return result.sections;
  },
);
