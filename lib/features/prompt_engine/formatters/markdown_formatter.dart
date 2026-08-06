/// OR-1160 — Markdown output formatter.
library;

import 'output_format.dart';

class MarkdownFormatter {
  const MarkdownFormatter();

  String format(StructuredPromptOutput output) {
    final buffer = StringBuffer();
    for (final block in output.blocks) {
      switch (block.type) {
        case OutputBlockType.summary:
          buffer.writeln('## Özet');
          buffer.writeln(block.content);
          buffer.writeln();
        case OutputBlockType.section:
          if (block.title != null) buffer.writeln('## ${block.title}');
          buffer.writeln(block.content);
          buffer.writeln();
        case OutputBlockType.list:
          if (block.title != null) buffer.writeln('### ${block.title}');
          for (final item in block.items) {
            buffer.writeln('- $item');
          }
          buffer.writeln();
        case OutputBlockType.highlight:
          buffer.writeln('> **${block.title ?? 'Vurgu'}**');
          buffer.writeln('> ${block.content}');
          buffer.writeln();
        case OutputBlockType.advice:
          buffer.writeln('### Tavsiye');
          buffer.writeln(block.content);
          buffer.writeln();
        case OutputBlockType.warning:
          buffer.writeln('> ⚠ **Uyarı**');
          buffer.writeln('> ${block.content}');
          buffer.writeln();
        case OutputBlockType.markdown:
        case OutputBlockType.richText:
          buffer.writeln(block.content);
          buffer.writeln();
      }
    }
    return buffer.toString().trim();
  }
}
