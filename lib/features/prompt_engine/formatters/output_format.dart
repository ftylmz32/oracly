/// OR-1160 — Structured output block types for AI responses.
library;

enum OutputBlockType {
  markdown,
  richText,
  section,
  list,
  highlight,
  advice,
  warning,
  summary,
}

class OutputBlock {
  const OutputBlock({
    required this.type,
    required this.content,
    this.title,
    this.items = const [],
    this.metadata = const {},
  });

  final OutputBlockType type;
  final String content;
  final String? title;
  final List<String> items;
  final Map<String, String> metadata;
}

class StructuredPromptOutput {
  const StructuredPromptOutput({
    required this.blocks,
    this.format = OutputFormatKind.markdown,
  });

  final List<OutputBlock> blocks;
  final OutputFormatKind format;

  String? blockByType(OutputBlockType type) {
    for (final block in blocks) {
      if (block.type == type) return block.content;
    }
    return null;
  }
}

enum OutputFormatKind {
  markdown,
  richText,
  structured,
}

class OutputFormatSchema {
  const OutputFormatSchema({
    required this.id,
    required this.name,
    required this.instructionTemplate,
    this.requiredBlocks = const [],
    this.optionalBlocks = const [],
  });

  final String id;
  final String name;
  final String instructionTemplate;
  final List<OutputBlockType> requiredBlocks;
  final List<OutputBlockType> optionalBlocks;
}
