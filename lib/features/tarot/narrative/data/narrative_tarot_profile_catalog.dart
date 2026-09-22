/// Authoritative Narrative Tarot V2 profile catalog (Major Arcana in Phase 3A).
///
/// Lookup never silently fabricates a profile from legacy deck data.
/// Missing V2 profile returns null — observable to callers.
///
/// NOT wired into the user reading path in Phase 3A.
library;

import '../domain/narrative_card_profile.dart';
import 'profiles/narrative_major_profiles.dart';

abstract final class NarrativeTarotProfileCatalog {
  NarrativeTarotProfileCatalog._();

  static final Map<String, NarrativeCardProfile> _byId = {
    for (final p in kNarrativeMajorProfiles) p.canonicalCardId: p,
  };

  static List<NarrativeCardProfile> get all =>
      List<NarrativeCardProfile>.unmodifiable(kNarrativeMajorProfiles);

  static List<NarrativeCardProfile> get majorProfiles => all;

  static bool contains(String canonicalCardId) =>
      _byId.containsKey(canonicalCardId);

  /// Returns null when no V2 profile exists (e.g. Minor Arcana in Phase 3A).
  static NarrativeCardProfile? lookup(String canonicalCardId) =>
      _byId[canonicalCardId];

  static int get count => _byId.length;
}
