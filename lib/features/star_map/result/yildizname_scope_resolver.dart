/// Fail-closed scope resolution from STORED evidence only.
///
/// Never recalculates astronomy, never calls a provider, never mutates an
/// artifact. Every disagreement between markers resolves toward the LIGHTER
/// claim — a reading is never presented as richer than its evidence proves.
library;

import 'yildizname_result_types.dart';

/// The scope a reading may honestly claim, plus which optional layers the
/// stored request actually carries.
final class YildiznameResolvedScope {
  const YildiznameResolvedScope({
    required this.scope,
    this.hasAscendant = false,
    this.hasMidheaven = false,
    this.hasHouses = false,
    this.hasAspects = false,
  });

  /// Fixed resolution for legacy-local results.
  static const legacy = YildiznameResolvedScope(
    scope: YildiznameResultScope.legacy,
  );

  final YildiznameResultScope scope;
  final bool hasAscendant;
  final bool hasMidheaven;
  final bool hasHouses;
  final bool hasAspects;

  /// True only when FULL and every optional natal layer is really present.
  bool get fullLayersComplete =>
      scope == YildiznameResultScope.full &&
      hasAscendant &&
      hasMidheaven &&
      hasHouses &&
      hasAspects;

  @override
  bool operator ==(Object other) =>
      other is YildiznameResolvedScope &&
      other.scope == scope &&
      other.hasAscendant == hasAscendant &&
      other.hasMidheaven == hasMidheaven &&
      other.hasHouses == hasHouses &&
      other.hasAspects == hasAspects;

  @override
  int get hashCode =>
      Object.hash(scope, hasAscendant, hasMidheaven, hasHouses, hasAspects);
}

abstract final class YildiznameScopeResolver {
  YildiznameScopeResolver._();

  /// Resolves the claimable scope of a Narrative reading.
  ///
  /// Inputs are the artifact-level markers plus the stored request / result
  /// snapshots. Unknown or missing evidence never raises the claim.
  static YildiznameResolvedScope resolveNarrative({
    String? artifactScope,
    String? artifactFidelity,
    Map<String, dynamic>? request,
    Map<String, dynamic>? result,
  }) {
    // 1. Every declared marker is a claim; the lightest claim wins.
    final claims = <int>[];
    void claim(Object? raw, int? Function(String) parse) {
      if (raw == null) return;
      final text = raw is String ? raw.trim() : '';
      if (raw is String && text.isEmpty) return; // absent, not conflicting
      // Present but unrecognized (or a non-string) → cannot support any claim.
      claims.add(raw is String ? (parse(text) ?? 0) : 0);
    }

    claim(artifactScope, _rankOfScope);
    claim(artifactFidelity, _rankOfFidelity);
    claim(request?['scope'], _rankOfScope);
    claim(request?['fidelity'], _rankOfFidelity);
    claim(result?['scope'], _rankOfScope);
    final claimRank = claims.isEmpty ? 0 : claims.reduce(_min);

    // 2. Structural evidence actually stored on the request.
    final structRank = request == null ? 0 : _structuralRank(request);

    // 3. The request's own omission list can only lower the claim further.
    final omitted = request == null ? const <String>{} : _omitted(request);
    final omissionCap = _omissionCap(omitted);

    final rank = _min(_min(claimRank, structRank), omissionCap);
    final scope = YildiznameResultScope.ofRank(rank);
    if (scope != YildiznameResultScope.full || request == null) {
      return YildiznameResolvedScope(scope: scope);
    }

    // 4. FULL never means "every layer" — report only what is really there.
    final angles = _maps(request['angles']);
    return YildiznameResolvedScope(
      scope: scope,
      hasAscendant:
          angles.any((a) => _isAngle(a, 'ascendant')) &&
          !omitted.contains('ascendant'),
      hasMidheaven:
          angles.any((a) => _isAngle(a, 'midheaven')) &&
          !omitted.contains('midheaven'),
      hasHouses:
          _maps(request['houses']).isNotEmpty && !omitted.contains('houses'),
      hasAspects:
          _maps(request['aspects']).isNotEmpty && !omitted.contains('aspects'),
    );
  }

  static int _min(int a, int b) => a < b ? a : b;

  static int? _rankOfScope(String raw) => switch (raw) {
    'legacy' => 0,
    'reduced' => 1,
    'full' => 2,
    _ => null,
  };

  static int? _rankOfFidelity(String raw) => switch (raw) {
    'tropicalSunSign' => 0,
    'reducedNatal' => 1,
    'fullNatalEphemeris' => 2,
    _ => null,
  };

  /// FULL needs exact structure (degrees / angles / houses / aspects /
  /// house system); REDUCED needs more than a bare Sun or a stored balance.
  static int _structuralRank(Map<String, dynamic> request) {
    final placements = _maps(request['placements']);
    final exactDegrees = placements.any((p) => p['degreeWithinSign'] != null);
    final houseSystem = request['houseSystem'];
    final hasHouseSystem =
        houseSystem is String && houseSystem.trim().isNotEmpty;
    if (exactDegrees ||
        hasHouseSystem ||
        _maps(request['angles']).isNotEmpty ||
        _maps(request['houses']).isNotEmpty ||
        _maps(request['aspects']).isNotEmpty) {
      return 2;
    }
    final beyondSun = placements.any((p) => p['body'] != 'sun');
    if (beyondSun || _maps(request['balances']).isNotEmpty) return 1;
    return 0;
  }

  /// Reduced / legacy requests record what they dropped; a FULL claim that
  /// also lists those drops is contradicted by its own request.
  static int _omissionCap(Set<String> omitted) {
    if (omitted.contains('personalPlanets') || omitted.contains('moon')) {
      return 0;
    }
    if (omitted.contains('exactDegrees')) return 1;
    return 2;
  }

  static Set<String> _omitted(Map<String, dynamic> request) {
    final raw = request['omittedLayers'];
    if (raw is! List) return const {};
    return {
      for (final e in raw)
        if (e is String && e.trim().isNotEmpty) e.trim(),
    };
  }

  static List<Map<String, dynamic>> _maps(Object? raw) {
    if (raw is! List) return const [];
    // A non-string-keyed entry is malformed evidence: skipped, never thrown on.
    return [
      for (final e in raw)
        if (e is Map && e.keys.every((k) => k is String))
          Map<String, dynamic>.from(e),
    ];
  }

  static bool _isAngle(Map<String, dynamic> fact, String kind) =>
      fact['factRef'] == 'angle.$kind' || fact['kind'] == kind;
}
