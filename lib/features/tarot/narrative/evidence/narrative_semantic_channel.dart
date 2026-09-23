/// FR-F04 semantic channel merge — Phase 3D.1B.
///
/// Same ontology id on keywordIds + symbolTags counts once.
library;

import '../domain/narrative_keyword_ids.dart';
import 'narrative_evidence_error.dart';

class NarrativeSemanticChannel {
  const NarrativeSemanticChannel._({
    required this.keywordIds,
    required this.ontologyTagIds,
    required this.tagOnlyIds,
    required this.semanticIds,
    required this.keywordTagDuplicateIds,
  });

  /// Exact orientation keyword ids (validated + sorted).
  final List<String> keywordIds;

  /// Symbol tags that also exist in [NarrativeKeywordIds.all] (sorted).
  final List<String> ontologyTagIds;

  /// Symbol tags outside the keyword ontology (sorted).
  final List<String> tagOnlyIds;

  /// Unique union of keywordIds ∪ ontologyTagIds (sorted) — FR-F04.
  final List<String> semanticIds;

  /// keywordIds ∩ ontologyTagIds (sorted).
  final List<String> keywordTagDuplicateIds;

  /// Pure FR-F04 channel factory. Does not require a card profile model.
  factory NarrativeSemanticChannel.from({
    required Iterable<String> keywordIds,
    required Iterable<String> symbolTags,
  }) {
    final keywords = <String>{};
    for (final id in keywordIds) {
      if (!NarrativeKeywordIds.all.contains(id)) {
        throw NarrativeEvidenceException(
          NarrativeEvidenceErrorCode.invalidOntologyId,
          message: 'unknown keyword id: $id',
        );
      }
      keywords.add(id);
    }

    final ontologyTags = <String>{};
    final tagOnly = <String>{};
    for (final tag in symbolTags) {
      if (NarrativeKeywordIds.all.contains(tag)) {
        ontologyTags.add(tag);
      } else {
        tagOnly.add(tag);
      }
    }

    final duplicates = keywords.intersection(ontologyTags);
    final semantic = <String>{...keywords, ...ontologyTags};

    List<String> sorted(Iterable<String> ids) {
      final list = ids.toList()..sort();
      return List<String>.unmodifiable(list);
    }

    return NarrativeSemanticChannel._(
      keywordIds: sorted(keywords),
      ontologyTagIds: sorted(ontologyTags),
      tagOnlyIds: sorted(tagOnly),
      semanticIds: sorted(semantic),
      keywordTagDuplicateIds: sorted(duplicates),
    );
  }
}
