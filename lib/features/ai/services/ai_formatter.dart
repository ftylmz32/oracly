/// OR-1110 — Formats AI content for display (markdown, code, citations).
library;

class FormattedBlock {
  const FormattedBlock({
    required this.type,
    required this.content,
    this.language,
  });

  final FormattedBlockType type;
  final String content;
  final String? language;
}

enum FormattedBlockType { paragraph, heading, code, quote, listItem, citation }

abstract final class AIFormatter {
  AIFormatter._();

  /// Splits markdown-ish content into renderable blocks.
  static List<FormattedBlock> toBlocks(String markdown) {
    final blocks = <FormattedBlock>[];
    final lines = markdown.split('\n');
    var inCode = false;
    final codeBuffer = StringBuffer();
    String? codeLang;

    for (final line in lines) {
      if (line.startsWith('```')) {
        if (!inCode) {
          inCode = true;
          codeLang = line.length > 3 ? line.substring(3).trim() : null;
        } else {
          blocks.add(FormattedBlock(
            type: FormattedBlockType.code,
            content: codeBuffer.toString().trimRight(),
            language: codeLang,
          ));
          codeBuffer.clear();
          inCode = false;
          codeLang = null;
        }
        continue;
      }

      if (inCode) {
        codeBuffer.writeln(line);
        continue;
      }

      if (line.startsWith('> ')) {
        blocks.add(FormattedBlock(
          type: FormattedBlockType.quote,
          content: line.substring(2),
        ));
      } else if (line.startsWith('## ')) {
        blocks.add(FormattedBlock(
          type: FormattedBlockType.heading,
          content: line.substring(3),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        blocks.add(FormattedBlock(
          type: FormattedBlockType.listItem,
          content: line.substring(2),
        ));
      } else if (line.trim().isNotEmpty) {
        blocks.add(FormattedBlock(
          type: FormattedBlockType.paragraph,
          content: line,
        ));
      }
    }

    return blocks;
  }

  /// Inline bold/italic stripping for plain preview.
  static String toPlainText(String markdown) {
    return markdown
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
        .replaceAll(RegExp(r'`(.+?)`'), r'$1');
  }
}
