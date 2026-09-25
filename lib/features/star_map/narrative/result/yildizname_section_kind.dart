/// Allowed Narrative V1 section kinds.
library;

enum YildiznameSectionKind {
  coreIdentity('core_identity'),
  emotionalWorld('emotional_world'),
  mindAndExpression('mind_and_expression'),
  relationshipsAndValues('relationships_and_values'),
  driveAndGrowth('drive_and_growth'),
  anglesAndHouses('angles_and_houses'),
  patternsAndTensions('patterns_and_tensions'),
  strengthsAndResources('strengths_and_resources'),
  archiveEcho('archive_echo'),
  practicalReflection('practical_reflection');

  const YildiznameSectionKind(this.wireName);
  final String wireName;

  static YildiznameSectionKind? tryParse(String raw) {
    for (final k in values) {
      if (k.wireName == raw) return k;
    }
    return null;
  }
}
