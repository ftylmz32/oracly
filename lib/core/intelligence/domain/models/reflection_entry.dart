/// RC-009 — Personal reflection entry across reading and ritual sources.
library;

enum JourneyReflectionSource {
  reading,
  ritual,
  dream,
  astrology,
  conversation,
}

class ReflectionEntry {
  const ReflectionEntry({
    required this.id,
    required this.source,
    required this.recordedAt,
    required this.text,
  });

  final String id;
  final JourneyReflectionSource source;
  final DateTime recordedAt;
  final String text;
}
