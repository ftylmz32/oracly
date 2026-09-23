/// Request-side bounded profile slice (Phase 3D.1A).
///
/// Derived from [NarrativeCardProfile]; never mutates the source.
library;

import '../../../../core/l10n/l10n_triple.dart';
import '../domain/narrative_card_profile.dart';
import '../domain/reversed_transform_kind.dart';
import 'narrative_question_grounding.dart';

class TarotNarrativeProfileSlice {
  const TarotNarrativeProfileSlice({
    required this.coreMeaning,
    required this.orientationExpression,
    required this.keywordIds,
    required this.symbolTags,
    required this.transforms,
    this.light,
    this.shadow,
    this.tension,
    this.desire,
    this.fear,
    this.relationshipDynamic,
    this.decisionDynamic,
    this.actionDirection,
  });

  final L10nTriple coreMeaning;
  final L10nTriple orientationExpression;
  final List<String> keywordIds;
  final List<String> symbolTags;
  final List<ReversedTransformKind> transforms;
  final L10nTriple? light;
  final L10nTriple? shadow;
  final L10nTriple? tension;
  final L10nTriple? desire;
  final L10nTriple? fear;
  final L10nTriple? relationshipDynamic;
  final L10nTriple? decisionDynamic;
  final L10nTriple? actionDirection;

  /// Pure deterministic slice from an authored profile.
  factory TarotNarrativeProfileSlice.fromProfile(
    NarrativeCardProfile profile, {
    required bool isReversed,
    required QuestionKind questionKind,
  }) {
    final orientation = isReversed ? profile.reversed : profile.upright;
    final keywordIds = List<String>.unmodifiable(
      List<String>.from(orientation.keywordIds),
    );
    final symbolTags = List<String>.unmodifiable(
      List<String>.from(profile.symbolTags),
    );
    final transforms = isReversed
        ? List<ReversedTransformKind>.unmodifiable(
            List<ReversedTransformKind>.from(orientation.transforms),
          )
        : const <ReversedTransformKind>[];

    L10nTriple? light;
    L10nTriple? shadow;
    L10nTriple? tension;
    L10nTriple? desire;
    L10nTriple? fear;
    L10nTriple? relationshipDynamic;
    L10nTriple? decisionDynamic;
    L10nTriple? actionDirection;

    switch (questionKind) {
      case QuestionKind.open:
        light = profile.light;
        shadow = profile.shadow;
        tension = profile.tension;
      case QuestionKind.guidance:
        light = profile.light;
        shadow = profile.shadow;
        tension = profile.tension;
        actionDirection = profile.actionDirection;
      case QuestionKind.relationship:
        relationshipDynamic = profile.relationshipDynamic;
        desire = profile.desire;
        fear = profile.fear;
        tension = profile.tension;
      case QuestionKind.decision:
        decisionDynamic = profile.decisionDynamic;
        actionDirection = profile.actionDirection;
        tension = profile.tension;
        fear = profile.fear;
    }

    return TarotNarrativeProfileSlice(
      coreMeaning: profile.coreMeaning,
      orientationExpression: orientation.expression,
      keywordIds: keywordIds,
      symbolTags: symbolTags,
      transforms: transforms,
      light: light,
      shadow: shadow,
      tension: tension,
      desire: desire,
      fear: fear,
      relationshipDynamic: relationshipDynamic,
      decisionDynamic: decisionDynamic,
      actionDirection: actionDirection,
    );
  }
}
