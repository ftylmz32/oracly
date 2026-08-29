/// Source pickers for OR context selection — never dumps archives.
library;

import '../../../core/intelligence/services/personal_memory_relevance.dart';
import '../../../core/personality/or_explanation_mode.dart';
import '../../ai/production/models/conversation_turn.dart';
import '../models/reflection_context.dart';
import 'or_context_bucket_helpers.dart';
import 'or_long_term_memory_boundaries.dart';

abstract final class OrContextSelectionSources {
  OrContextSelectionSources._();

  static String? discovery(
    String? raw,
    String current,
    List<ConversationTurn> recent,
  ) {
    final base = (raw ?? '').trim();
    if (base.isEmpty) return null;
    final merged = OrExplanationMode.mergeHint(
      base,
      message: current,
      turns: recent,
    );
    if (merged == null || merged.trim().isEmpty) return null;
    return OrLongTermMemoryBoundaries.tag(OrMemoryKind.observation, merged);
  }

  static String? feature(String? raw) {
    final body = (raw ?? '').trim();
    if (body.isEmpty || !OrContextBucketHelpers.looksFeature(body)) {
      return null;
    }
    final capped = OrContextBucketHelpers.cap(
      body,
      OrContextBucketHelpers.featureCap,
    );
    return OrLongTermMemoryBoundaries.tag(OrMemoryKind.interpretation, capped);
  }

  static String? memory({
    required ReflectionContext? reflection,
    required String current,
    required bool discoveryTaken,
    required bool featureTaken,
  }) {
    if (discoveryTaken || featureTaken) return null;
    final obs = PersonalMemoryRelevance.filterObservation(
      reflection?.proactiveAcknowledgment,
      current,
    );
    if (obs != null && !OrContextBucketHelpers.looksFeature(obs)) {
      return OrLongTermMemoryBoundaries.tag(
        OrMemoryKind.observation,
        OrContextBucketHelpers.cap(obs, OrContextBucketHelpers.memoryCap),
      );
    }
    final saved = OrContextBucketHelpers.relevantSaved(
      reflection?.savedMemories ?? const [],
      current,
    );
    if (saved == null) return null;
    return OrLongTermMemoryBoundaries.tag(OrMemoryKind.fact, saved);
  }

  /// True when proactive observation already fills the memory bucket.
  static bool usedProactiveObservation({
    required ReflectionContext? reflection,
    required String current,
    required bool discoveryTaken,
    required bool featureTaken,
  }) {
    if (discoveryTaken || featureTaken) return false;
    final obs = PersonalMemoryRelevance.filterObservation(
      reflection?.proactiveAcknowledgment,
      current,
    );
    return obs != null && !OrContextBucketHelpers.looksFeature(obs);
  }

  /// Soft PREFERENCE from [PersonalMemoryService.promptHint] — never a dump.
  static String? memoryPreference({
    required String? promptHint,
    required String? proactiveAcknowledgment,
    required bool skipBecauseObservation,
  }) {
    final raw = (promptHint ?? '').trim();
    if (raw.isEmpty || skipBecauseObservation) return null;
    final ack = (proactiveAcknowledgment ?? '').trim();
    if (ack.isNotEmpty && _nearDuplicate(raw, ack)) return null;
    return OrLongTermMemoryBoundaries.tag(
      OrMemoryKind.preference,
      OrContextBucketHelpers.cap(raw, OrContextBucketHelpers.preferenceCap),
    );
  }

  static bool _nearDuplicate(String a, String b) {
    final x = a.toLowerCase();
    final y = b.toLowerCase();
    if (x == y) return true;
    final seed = x.length <= y.length ? x : y;
    final host = x.length <= y.length ? y : x;
    if (seed.length < 24) return false;
    return host.contains(seed.substring(0, seed.length.clamp(24, 48)));
  }
}
