/// Locked scoring constants, kind triggers, admission helpers (3D.1C).
library;

import '../domain/narrative_keyword_ids.dart';
import '../domain/reversed_transform_kind.dart';
import 'narrative_keyword_contrasts.dart';
import 'narrative_question_grounding.dart';
import 'narrative_spread_semantics.dart';

abstract final class NarrativeRelationshipRules {
  NarrativeRelationshipRules._();

  static const maxRelationshipsDefault = 12;
  static const scoreClampMax = 3.5;
  static const frOverlapCap = 0.35;
  static const frStrengthCap = 0.45;
  static const hardContrast = 0.70;
  static const contextualContrast = 0.45;
  static const transformEach = 0.15;
  static const transformCap = 0.30;
  static const canonicalBonus = 0.55;
  static const questionBonus = 0.15;
  static const themeOverlapMin = 2.0;
  static const reinforcementMeanRawMin = 4.0;

  static const positionBonus = <PositionEdgeKind, double>{
    PositionEdgeKind.opposition: 0.40,
    PositionEdgeKind.temporal: 0.35,
    PositionEdgeKind.supportive: 0.30,
    PositionEdgeKind.pressure: 0.35,
    PositionEdgeKind.mirror: 0.25,
  };

  static const questionRelationshipIds = <String>{
    NarrativeKeywordIds.belonging,
    NarrativeKeywordIds.intimacy,
    NarrativeKeywordIds.reciprocity,
    NarrativeKeywordIds.union,
    NarrativeKeywordIds.attachment,
    NarrativeKeywordIds.nurture,
    NarrativeKeywordIds.coldness,
    NarrativeKeywordIds.isolation,
  };

  static const questionDecisionIds = <String>{
    NarrativeKeywordIds.choice,
    NarrativeKeywordIds.direction,
    NarrativeKeywordIds.indecision,
    NarrativeKeywordIds.pause,
    NarrativeKeywordIds.momentum,
    NarrativeKeywordIds.resistance,
    NarrativeKeywordIds.clarity,
  };

  static const blockageKeywords = <String>{
    NarrativeKeywordIds.delay,
    NarrativeKeywordIds.resistance,
    NarrativeKeywordIds.stagnation,
    NarrativeKeywordIds.bondage,
    NarrativeKeywordIds.suppression,
    NarrativeKeywordIds.closing,
    NarrativeKeywordIds.rigidity,
  };

  static const blockageTransforms = <ReversedTransformKind>{
    ReversedTransformKind.delay,
    ReversedTransformKind.blockedExpression,
  };

  static const softeningKeywords = <String>{
    NarrativeKeywordIds.restraint,
    NarrativeKeywordIds.compassion,
    NarrativeKeywordIds.pause,
    NarrativeKeywordIds.balance,
    NarrativeKeywordIds.nurture,
  };

  static const escalationKeywords = <String>{
    NarrativeKeywordIds.haste,
    NarrativeKeywordIds.anger,
    NarrativeKeywordIds.overflow,
    NarrativeKeywordIds.scatter,
    NarrativeKeywordIds.impatience,
  };

  static const escalationTransforms = <ReversedTransformKind>{
    ReversedTransformKind.excess,
  };

  static const resolutionKeywords = <String>{
    NarrativeKeywordIds.integration,
    NarrativeKeywordIds.clarity,
    NarrativeKeywordIds.balance,
    NarrativeKeywordIds.renewal,
    NarrativeKeywordIds.release,
    NarrativeKeywordIds.opening,
    NarrativeKeywordIds.reciprocity,
  };

  static double questionScore(QuestionKind kind, Set<String> shared) {
    switch (kind) {
      case QuestionKind.open:
      case QuestionKind.guidance:
        return 0;
      case QuestionKind.relationship:
        return shared.any(questionRelationshipIds.contains) ? questionBonus : 0;
      case QuestionKind.decision:
        return shared.any(questionDecisionIds.contains) ? questionBonus : 0;
    }
  }

  static double contrastScore(NarrativeKeywordContrastClass? c) => switch (c) {
    NarrativeKeywordContrastClass.hard => hardContrast,
    NarrativeKeywordContrastClass.contextual => contextualContrast,
    null => 0,
  };

  static double clampTotal(double raw) {
    if (raw < 0) return 0;
    if (raw > scoreClampMax) return scoreClampMax;
    return raw;
  }
}
