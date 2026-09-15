library;

import 'oracly_context_packet.dart';
import 'oracly_memory.dart';
import 'oracly_memory_store.dart';

class OraclyMemoryRetriever {
  const OraclyMemoryRetriever(this.store);
  final OraclyMemoryStore store;

  /// Small cross-feature candidates for the backend evidence phase. These are
  /// never writer context until current visual evidence selects a match.
  List<Map<String, dynamic>> evidenceCandidates({
    required OraclyReadingType currentType,
    int maxItems = 3,
  }) {
    return store.all()
        .where((m) => m.kind == OraclyMemoryKind.reading &&
            m.source.type != currentType &&
            m.themes.isNotEmpty)
        .take(maxItems)
        .map((m) => <String, dynamic>{
              'sourceId': m.source.id,
              'sourceType': m.source.type.name,
              'sourceDate': m.source.occurredAt.toIso8601String(),
              'themes': m.themes.take(3).toList(),
              'summary': m.summary.length <= 120
                  ? m.summary
                  : m.summary.substring(0, 120),
            })
        .toList(growable: false);
  }

  /// Reading-safe context. An empty query never sends history because
  /// relevance cannot be established before generation.
  String? forInterpretation({
    required String query,
    required OraclyReadingType currentType,
    List<String> currentEvidence = const [],
    int maxCharacters = 220,
  }) {
    if (query.trim().isEmpty && currentEvidence.isEmpty) return null;
    final packet = retrieve(
      query: query,
      currentEvidence: currentEvidence,
      excludeType: currentType,
      maxItems: 2,
      maxCharacters: maxCharacters,
    );
    if (packet.items.isEmpty) return null;
    final rows = packet.items
        .map((item) {
          final source = item.memory.source;
          final date =
              '${source.occurredAt.year.toString().padLeft(4, '0')}-'
              '${source.occurredAt.month.toString().padLeft(2, '0')}-'
              '${source.occurredAt.day.toString().padLeft(2, '0')}';
          return '[${source.type.name}|$date|${source.id}] ${item.memory.summary}';
        })
        .join(' ');
    final raw = 'Yalnızca şimdiki kanıt desteklerse kullan: $rows';
    final prompt = raw.length <= maxCharacters
        ? raw
        : raw.substring(0, maxCharacters);
    return prompt.isEmpty ? null : prompt;
  }

  OraclyContextPacket retrieve({
    required String query,
    List<String> currentEvidence = const [],
    OraclyReadingType? excludeType,
    int maxItems = 4,
    int maxCharacters = 1200,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final queryTokens = _tokens('$query ${currentEvidence.join(' ')}');
    final explicitRecall = _isRecall(query);
    final scored = <OraclyContextItem>[];
    for (final memory in store.all()) {
      if (excludeType != null && memory.source.type == excludeType) continue;
      final haystack = _tokens(
        [
          memory.summary,
          ...memory.themes,
          ...memory.evidence,
          ...memory.emotionalThemes,
          ...memory.intentions,
          ...memory.unresolvedThreads,
        ].join(' '),
      );
      final overlap = queryTokens
          .where(
            (queryToken) => haystack.any(
              (memoryToken) =>
                  queryToken == memoryToken ||
                  (queryToken.length >= 5 &&
                      memoryToken.length >= 5 &&
                      (queryToken.startsWith(memoryToken) ||
                          memoryToken.startsWith(queryToken))),
            ),
          )
          .length;
      final ageDays = clock.difference(memory.source.occurredAt).inDays.abs();
      final recency = 1 / (1 + ageDays / 30);
      final score = overlap * 2.0 + recency * .45 + memory.confidence * .25;
      if (overlap == 0 && !explicitRecall) continue;
      if (overlap == 0 && explicitRecall && ageDays > 365) continue;
      scored.add(OraclyContextItem(memory: memory, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    final bounded = <OraclyContextItem>[];
    var chars = 0;
    for (final item in scored) {
      if (bounded.length >= maxItems) break;
      final cost = item.memory.summary.length + 70;
      if (bounded.isNotEmpty && chars + cost > maxCharacters) break;
      bounded.add(item);
      chars += cost;
    }
    final counts = <String, Set<OraclyReadingType>>{};
    for (final item in bounded) {
      for (final theme in item.memory.themes) {
        counts
            .putIfAbsent(theme.toLowerCase(), () => {})
            .add(item.memory.source.type);
      }
    }
    final recurring = counts.entries
        .where((e) => e.value.length >= 2)
        .map((e) => e.key)
        .take(3)
        .toList();
    return OraclyContextPacket(
      currentIntent: query.trim().isEmpty ? null : query.trim(),
      currentEvidence: currentEvidence,
      items: bounded,
      recurringThemes: recurring,
    );
  }

  static bool _isRecall(String text) {
    final t = text.toLowerCase();
    return [
      'geçen',
      'önce',
      'hatırla',
      'falımda',
      'benziyor',
      'tema',
      'previous',
      'remember',
      'before',
      'similar',
    ].any(t.contains);
  }

  static Set<String> _tokens(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9çğıöşü]+'), ' ')
      .split(' ')
      .where((e) => e.length >= 3 && !_stop.contains(e))
      .toSet();

  static const _stop = {
    'bir',
    'ile',
    'için',
    'ama',
    'gibi',
    'olan',
    'this',
    'that',
    'the',
    'and',
    'from',
  };
}
