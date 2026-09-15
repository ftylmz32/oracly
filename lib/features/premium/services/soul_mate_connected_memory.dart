/// Bounded read-side memory selected only from the current explicit intention.
library;

import '../../../core/memory/oracly_memory.dart';
import '../../../core/memory/oracly_memory_retriever.dart';

abstract final class SoulMateConnectedMemory {
  SoulMateConnectedMemory._();

  static String? select({
    required OraclyMemoryRetriever retriever,
    required String? intention,
  }) {
    final query = intention?.trim() ?? '';
    if (query.length < 8) return null;
    try {
      return retriever.forInterpretation(
        query: query,
        currentType: OraclyReadingType.soulmate,
      );
    } catch (_) {
      return null;
    }
  }
}
