/// Authoritative Narrative Tarot V2 profile catalog.
///
/// Phase 3B1: Major (22) + Wands (14) = 36 profiles.
/// Lookup never silently fabricates a profile from legacy deck data.
/// Missing V2 profile returns null — observable to callers.
///
/// NOT wired into the user reading path.
library;

import '../domain/narrative_card_profile.dart';
import 'profiles/narrative_major_profiles.dart';
import 'profiles/narrative_wands_profiles.dart';

abstract final class NarrativeTarotProfileCatalog {
  NarrativeTarotProfileCatalog._();

  static final List<NarrativeCardProfile> _all = List.unmodifiable([
    ...kNarrativeMajorProfiles,
    ...kNarrativeWandsProfiles,
  ]);

  static final Map<String, NarrativeCardProfile> _byId = {
    for (final p in _all) p.canonicalCardId: p,
  };

  static List<NarrativeCardProfile> get all => _all;

  static List<NarrativeCardProfile> get majorProfiles =>
      List.unmodifiable(kNarrativeMajorProfiles);

  static List<NarrativeCardProfile> get minorProfiles =>
      List.unmodifiable(kNarrativeWandsProfiles);

  static List<NarrativeCardProfile> get wandsProfiles =>
      List.unmodifiable(kNarrativeWandsProfiles);

  static bool contains(String canonicalCardId) =>
      _byId.containsKey(canonicalCardId);

  /// Returns null when no V2 profile exists (e.g. Cups in Phase 3B1).
  static NarrativeCardProfile? lookup(String canonicalCardId) =>
      _byId[canonicalCardId];

  static int get count => _byId.length;
}
