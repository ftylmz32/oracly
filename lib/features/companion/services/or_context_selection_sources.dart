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
    return OrLongTermMemoryBoundaries.tag(
      OrMemoryKind.observation,
      merged,
    );
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
    return OrLongTermMemoryBoundaries.tag(
      OrMemoryKind.interpretation,
      capped,
    );
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
}
