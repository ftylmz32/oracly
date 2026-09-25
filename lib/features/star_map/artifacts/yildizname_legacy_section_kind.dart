/// Stable machine ids for legacy StarMap leaf types — not display titles.
library;

enum YildiznameLegacySectionKind {
  skyMessage('sky_message'),
  innerArchive('inner_archive'),
  planetCatalogue('planet_catalogue');

  const YildiznameLegacySectionKind(this.wireName);
  final String wireName;

  static YildiznameLegacySectionKind? tryParse(String? raw) {
    if (raw == null) return null;
    for (final v in values) {
      if (v.wireName == raw || v.name == raw) return v;
    }
    return null;
  }
}
