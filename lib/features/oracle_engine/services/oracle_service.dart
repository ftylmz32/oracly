/// OR-1140 — Central oracle orchestrator.
library;

import '../core/engine_contract.dart';
import '../core/oracle_context.dart';
import '../core/oracle_engine_type.dart';
import '../core/oracle_result.dart';
import '../domain/oracle_reading_repository.dart';

abstract class OracleService {
  OracleEngineRegistry get registry;
  Future<OracleResult<T>> run<T>({
    required OracleEngineType engine,
    required dynamic input,
    OracleContext? context,
  });
}

class DefaultOracleService implements OracleService {
  DefaultOracleService({
    required this.engineRegistry,
    this.readingRepository,
  });

  final OracleEngineRegistry engineRegistry;
  final OracleReadingRepository? readingRepository;

  @override
  OracleEngineRegistry get registry => engineRegistry;

  @override
  Future<OracleResult<T>> run<T>({
    required OracleEngineType engine,
    required dynamic input,
    OracleContext? context,
  }) async {
    final resolved = engineRegistry.resolve(engine);
    if (resolved == null) {
      throw StateError('No engine registered for $engine');
    }

    final ctx = context ??
        OracleContext(
          sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          activeEngine: engine,
        );

    final result = await resolved.execute(input: input, context: ctx);
    await readingRepository?.save(result);
    return result as OracleResult<T>;
  }
}
