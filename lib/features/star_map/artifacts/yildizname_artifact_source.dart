/// Yıldızname artifact provenance — never blur legacy vs narrative.
library;

enum YildiznameArtifactSource {
  legacyLocal('legacy_local'),
  narrativeV1('narrative_v1');

  const YildiznameArtifactSource(this.wireName);
  final String wireName;

  static YildiznameArtifactSource? tryParse(String? raw) {
    if (raw == null) return null;
    for (final v in values) {
      if (v.wireName == raw || v.name == raw) return v;
    }
    return null;
  }
}
