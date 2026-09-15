/// Canonical, source-attributed memory records shared by every ORACLY feature.
library;

enum OraclyMemoryKind { stableFact, reading, conversation }

enum OraclyReadingType {
  tarot,
  coffee,
  palm,
  soulmate,
  astrology,
  birthChart,
  dream,
  orConversation,
}

class OraclyMemorySource {
  const OraclyMemorySource({
    required this.id,
    required this.type,
    required this.occurredAt,
    this.resultRef,
  });

  final String id;
  final OraclyReadingType type;
  final DateTime occurredAt;
  final String? resultRef;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'occurredAt': occurredAt.toIso8601String(),
    if (resultRef != null) 'resultRef': resultRef,
  };

  factory OraclyMemorySource.fromJson(Map<String, dynamic> json) =>
      OraclyMemorySource(
        id: json['id'] as String,
        type: OraclyReadingType.values.byName(json['type'] as String),
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        resultRef: json['resultRef'] as String?,
      );
}

class OraclyMemory {
  const OraclyMemory({
    required this.id,
    required this.kind,
    required this.source,
    required this.summary,
    this.themes = const [],
    this.evidence = const [],
    this.emotionalThemes = const [],
    this.people = const [],
    this.intentions = const [],
    this.unresolvedThreads = const [],
    this.advice = const [],
    this.confidence = .7,
    this.updatedAt,
  });

  static const schemaVersion = 2;
  final String id;
  final OraclyMemoryKind kind;
  final OraclyMemorySource source;
  final String summary;
  final List<String> themes;
  final List<String> evidence;
  final List<String> emotionalThemes;
  final List<String> people;
  final List<String> intentions;
  final List<String> unresolvedThreads;
  final List<String> advice;
  final double confidence;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'kind': kind.name,
    'source': source.toJson(),
    'summary': summary,
    'themes': themes,
    'evidence': evidence,
    'emotionalThemes': emotionalThemes,
    'people': people,
    'intentions': intentions,
    'unresolvedThreads': unresolvedThreads,
    'advice': advice,
    'confidence': confidence,
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  factory OraclyMemory.fromJson(Map<String, dynamic> json) => OraclyMemory(
    id: json['id'] as String,
    kind: OraclyMemoryKind.values.byName(json['kind'] as String),
    source: OraclyMemorySource.fromJson(
      Map<String, dynamic>.from(json['source'] as Map),
    ),
    summary: _text(json['summary'], 360),
    themes: _list(json['themes'], 8, 48),
    evidence: _list(json['evidence'], 8, 80),
    emotionalThemes: _list(json['emotionalThemes'], 5, 48),
    people: _list(json['people'], 5, 48),
    intentions: _list(json['intentions'], 3, 120),
    unresolvedThreads: _list(json['unresolvedThreads'], 5, 100),
    advice: _list(json['advice'], 3, 120),
    confidence: ((json['confidence'] as num?) ?? .7).toDouble().clamp(0, 1),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );

  static String _text(Object? raw, int max) {
    final value = raw?.toString().trim() ?? '';
    return value.length <= max ? value : value.substring(0, max);
  }

  static List<String> _list(Object? raw, int count, int length) {
    if (raw is! List) return const [];
    return List.unmodifiable(
      raw.map((e) => _text(e, length)).where((e) => e.isNotEmpty).take(count),
    );
  }
}
