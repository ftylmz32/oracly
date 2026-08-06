/// OR-1140 — Dream engine input payload.
library;

class DreamEngineInput {
  const DreamEngineInput({
    required this.rawText,
    this.emotions = const [],
  });

  final String rawText;
  final List<String> emotions;
}
