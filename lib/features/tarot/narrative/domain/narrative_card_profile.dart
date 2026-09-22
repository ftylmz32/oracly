/// Narrative Tarot V2 — semantic card profile keyed by canonical deck id.
///
/// Separate from [OraclyTarotCard]. Does not replace deck identity.
library;

import '../../../../core/l10n/l10n_triple.dart';
import 'narrative_orientation_profile.dart';

class NarrativeCardProfile {
  const NarrativeCardProfile({
    required this.canonicalCardId,
    required this.coreMeaning,
    required this.light,
    required this.shadow,
    required this.tension,
    required this.desire,
    required this.fear,
    required this.relationshipDynamic,
    required this.decisionDynamic,
    required this.actionDirection,
    required this.upright,
    required this.reversed,
    required this.symbolTags,
    required this.profileRevision,
  });

  final String canonicalCardId;
  final L10nTriple coreMeaning;
  final L10nTriple light;
  final L10nTriple shadow;
  final L10nTriple tension;
  final L10nTriple desire;
  final L10nTriple fear;
  final L10nTriple relationshipDynamic;
  final L10nTriple decisionDynamic;
  final L10nTriple actionDirection;
  final NarrativeOrientationProfile upright;
  final NarrativeOrientationProfile reversed;
  final List<String> symbolTags;
  final int profileRevision;

  Iterable<L10nTriple> get semanticFields sync* {
    yield coreMeaning;
    yield light;
    yield shadow;
    yield tension;
    yield desire;
    yield fear;
    yield relationshipDynamic;
    yield decisionDynamic;
    yield actionDirection;
    yield upright.expression;
    yield reversed.expression;
  }
}
