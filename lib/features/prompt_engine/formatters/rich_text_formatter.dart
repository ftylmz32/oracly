/// OR-1160 — Rich text block serializer (plain structured text).
library;

import 'output_format.dart';

class RichTextFormatter {
  const RichTextFormatter();

  String format(StructuredPromptOutput output) {
    final buffer = StringBuffer();
    for (final block in output.blocks) {
      if (block.title != null) {
        buffer.writeln(block.title!.toUpperCase());
        buffer.writeln('-' * block.title!.length);
      }
      if (block.items.isNotEmpty) {
        for (final item in block.items) {
          buffer.writeln('• $item');
        }
      } else {
        buffer.writeln(block.content);
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }
}
