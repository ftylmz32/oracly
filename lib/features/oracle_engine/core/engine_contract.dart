/// OR-1140 — Engine contract — all engines implement this interface.
library;

import '../core/oracle_context.dart';
import '../core/oracle_engine_type.dart';
import '../core/oracle_result.dart';

abstract class OracleEngine<I, O> {
  OracleEngineType get type;

  Future<OracleResult<O>> execute({
    required I input,
    required OracleContext context,
  });
}

abstract class OracleEngineRegistry {
  OracleEngine<dynamic, dynamic>? resolve(OracleEngineType type);
  void register(OracleEngineType type, OracleEngine<dynamic, dynamic> engine);
}

class DefaultOracleEngineRegistry implements OracleEngineRegistry {
  final Map<OracleEngineType, OracleEngine<dynamic, dynamic>> _engines = {};

  @override
  OracleEngine<dynamic, dynamic>? resolve(OracleEngineType type) =>
      _engines[type];

  @override
  void register(OracleEngineType type, OracleEngine<dynamic, dynamic> engine) {
    _engines[type] = engine;
  }

  List<OracleEngineType> get registeredTypes => _engines.keys.toList();
}
