/// Only bodies we actually know — never invent Moon/planet placements.
library;

/// What the instrument may render. Absent fields stay blank on the sky.
class AstrologySupportedSky {
  const AstrologySupportedSky({
    required this.sunSignId,
    this.moonSignId,
    this.planetSignIds = const {},
  });

  /// Tropical Sun identity for this reading (always known when a sign is selected).
  final String sunSignId;

  /// Zodiac Moon only when a real ephemeris/natal calculation provided it.
  final String? moonSignId;

  /// Other planets only when calculated — map planet id → sign id.
  final Map<String, String> planetSignIds;

  bool get hasMoon => moonSignId != null && moonSignId!.isNotEmpty;

  bool hasPlanet(String id) =>
      (planetSignIds[id] ?? '').trim().isNotEmpty;
}
