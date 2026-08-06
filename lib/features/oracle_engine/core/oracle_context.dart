/// OR-1140 — Shared execution context for all engines.
library;

import 'oracle_engine_type.dart';

class OracleContext {
  const OracleContext({
    required this.sessionId,
    required this.timestamp,
    this.locale = 'tr',
    this.metadata = const {},
    this.activeEngine,
  });

  final String sessionId;
  final DateTime timestamp;
  final String locale;
  final Map<String, String> metadata;
  final OracleEngineType? activeEngine;

  OracleContext copyWith({
    String? locale,
    Map<String, String>? metadata,
    OracleEngineType? activeEngine,
  }) {
    return OracleContext(
      sessionId: sessionId,
      timestamp: timestamp,
      locale: locale ?? this.locale,
      metadata: metadata ?? this.metadata,
      activeEngine: activeEngine ?? this.activeEngine,
    );
  }
}
