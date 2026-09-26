/// Phase 7G — parse authoritative master table SHA-256 bindings (test-only).
library;

/// Parses `| \`file.png\` | … | \`hash\` |` rows into filename → sha256.
///
/// Rejects missing/duplicate filenames, non-64-hex hashes, and tables that
/// do not list exactly the declared inventory size when [expectedCount] set.
Map<String, String> yildiznamePhase7gParseManifestHashes(
  String markdown, {
  int expectedCount = 17,
}) {
  final row = RegExp(
    r'\|\s*`([a-z0-9_]+\.png)`\s*\|(?:[^|\n]*\|){4}\s*`([0-9a-f]{64})`\s*\|',
    multiLine: true,
  );
  final map = <String, String>{};
  for (final m in row.allMatches(markdown)) {
    final file = m.group(1)!;
    final hash = m.group(2)!;
    if (map.containsKey(file)) {
      throw StateError('duplicate manifest master row: $file');
    }
    map[file] = hash;
  }
  if (map.length != expectedCount) {
    throw StateError(
      'manifest master rows=${map.length}, expected=$expectedCount',
    );
  }
  return map;
}
