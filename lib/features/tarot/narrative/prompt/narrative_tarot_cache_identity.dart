/// Phase 6C — dormant SHA-256 Narrative V2 cache identity.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../evidence/narrative_request.dart';
import 'narrative_tarot_prompt_canonical.dart';
import 'narrative_tarot_prompt_input.dart';
import 'narrative_tarot_prompt_serializer.dart';

abstract final class NarrativeTarotCacheIdentity {
  NarrativeTarotCacheIdentity._();

  static const keyPrefix = 'narrative_tarot_v2_s1_';

  /// Digest only — never logs canonical preimage.
  static String keyFor(TarotNarrativeRequest request) {
    final input = NarrativeTarotPromptSerializer.serialize(request);
    return keyForInput(
      input: input,
      bounds: request.bounds,
      sessionId: request.sessionId,
      readingId: request.readingId,
    );
  }

  static String keyForInput({
    required NarrativeTarotPromptInput input,
    required RequestBounds bounds,
    required String sessionId,
    required String readingId,
  }) {
    final envelope = {
      'narrativeTarotVersion': input.narrativeTarotVersion,
      'serializerVersion': input.serializerVersion,
      'policyVersion': input.policy.version,
      'modelInput': NarrativeTarotPromptCanonical.toMap(input),
      'bounds': {
        'maxPriorReadingsScanned': bounds.maxPriorReadingsScanned,
        'maxRecurringOccurrencesListed': bounds.maxRecurringOccurrencesListed,
        'maxRelationships': bounds.maxRelationships,
        'maxMemoryChars': bounds.maxMemoryChars,
        'maxThemeLabels': bounds.maxThemeLabels,
      },
      'sessionId': sessionId,
      'readingId': readingId,
    };
    final canonical = jsonEncode(_sortDeep(envelope));
    final digest = sha256.convert(utf8.encode(canonical));
    return '$keyPrefix${digest.toString()}';
  }

  static Object? _sortDeep(Object? v) {
    if (v is Map) {
      final keys = v.keys.map((k) => '$k').toList()..sort();
      return {for (final k in keys) k: _sortDeep(v[k])};
    }
    if (v is List) return [for (final e in v) _sortDeep(e)];
    return v;
  }
}
