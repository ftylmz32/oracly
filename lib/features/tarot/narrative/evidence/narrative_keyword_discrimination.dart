/// Frozen ontology-revision-1 keyword discrimination — Phase 3D.1B.
///
/// Runtime weight() uses the const df map — never rescans the 78-card catalog.
library;

import 'dart:math' as math;

import '../domain/narrative_keyword_ids.dart';
import 'narrative_evidence_error.dart';

abstract final class NarrativeKeywordDiscrimination {
  NarrativeKeywordDiscrimination._();

  static const int ontologyRevision = 1;
  static const int orientationCount = 156;
  static const int highFrequencyDfThreshold = 8;

  /// Exact production df(id) for ontology revision 1 (keywordIds only).
  static const Map<String, int> documentFrequency = {
    'abundance': 1,
    'accountability': 4,
    'agency': 2,
    'anger': 3,
    'attachment': 1,
    'authority': 1,
    'avoidance': 3,
    'awakening': 1,
    'balance': 3,
    'belonging': 5,
    'bias': 1,
    'boast': 5,
    'bondage': 4,
    'boundary': 4,
    'burden': 6,
    'change': 4,
    'choice': 3,
    'clarity': 5,
    'closing': 2,
    'coldness': 5,
    'communication': 2,
    'compassion': 2,
    'completion': 2,
    'conformity': 1,
    'confusion': 4,
    'control': 9,
    'coordination': 1,
    'courage': 1,
    'craft': 3,
    'creation': 1,
    'curiosity': 4,
    'cycles': 3,
    'delay': 9,
    'denial': 6,
    'dependence': 0,
    'desire': 2,
    'despair': 4,
    'direction': 5,
    'discernment': 1,
    'discipline': 1,
    'discord': 3,
    'display': 8,
    'doubt': 7,
    'ending': 6,
    'enough': 4,
    'enthusiasm': 0,
    'envy': 1,
    'escape': 10,
    'exhaustion': 4,
    'externalDemand': 1,
    'fairness': 1,
    'fear': 8,
    'flow': 4,
    'focus': 3,
    'freedom': 1,
    'grief': 4,
    'guidance': 1,
    'harshSpeech': 7,
    'haste': 13,
    'holding': 5,
    'hope': 1,
    'illusion': 6,
    'imbalance': 4,
    'impatience': 2,
    'indecision': 5,
    'inquiry': 5,
    'instability': 5,
    'integration': 2,
    'internalStrain': 0,
    'intimacy': 1,
    'intuition': 1,
    'isolation': 9,
    'joy': 2,
    'judgment': 2,
    'labor': 0,
    'learning': 4,
    'listening': 0,
    'mastery': 2,
    'messenger': 5,
    'mindBurden': 2,
    'misdirection': 0,
    'momentum': 4,
    'mystery': 2,
    'notListening': 4,
    'nurture': 3,
    'opening': 6,
    'overflow': 6,
    'pause': 7,
    'perspective': 4,
    'pressure': 1,
    'principle': 1,
    'projection': 4,
    'receptivity': 1,
    'reciprocity': 2,
    'release': 3,
    'renewal': 3,
    'rescue': 2,
    'resistance': 5,
    'resource': 1,
    'restraint': 6,
    'rigidity': 7,
    'roots': 4,
    'scarcity': 3,
    'scatter': 14,
    'shadow': 1,
    'shame': 3,
    'silence': 3,
    'socialExpectation': 3,
    'solitude': 2,
    'spark': 3,
    'stability': 4,
    'stagnation': 6,
    'stewardship': 4,
    'strain': 4,
    'structure': 2,
    'suppression': 2,
    'teaching': 1,
    'threshold': 6,
    'timing': 3,
    'tradition': 1,
    'truth': 3,
    'uncertainty': 1,
    'union': 2,
    'values': 3,
    'vitality': 1,
    'will': 1,
    'wisdom': 1,
    'withdrawal': 13,
  };

  static int df(String id) {
    _requireOntology(id);
    return documentFrequency[id]!;
  }

  static bool isHighFrequency(String id) => df(id) >= highFrequencyDfThreshold;

  /// Locked formula: ln((N+1)/(df+1)) + 1, clamped to [1.0, 6.0].
  static double weight(String id) {
    final d = df(id);
    final raw = math.log((orientationCount + 1) / (d + 1)) + 1.0;
    if (raw < 1.0) return 1.0;
    if (raw > 6.0) return 6.0;
    return raw;
  }

  static void _requireOntology(String id) {
    if (!NarrativeKeywordIds.all.contains(id)) {
      throw NarrativeEvidenceException(
        NarrativeEvidenceErrorCode.invalidOntologyId,
        message: 'unknown keyword id: $id',
      );
    }
  }
}
