/// Turns insight markup into clean clipboard prose.
library;

abstract final class InsightCopyText {
  InsightCopyText._();

  static String joinBlocks(Iterable<String> blocks) {
    return clean(
      blocks.map((b) => b.trim()).where((b) => b.isNotEmpty).join('\n\n'),
    );
  }

  static String clean(String raw) {
    var text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '\n');
    text = text.replaceAllMapped(RegExp(r'`([^`]*)`'), (m) => m[1]!);
    text = text.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m[1]!);
    text = text.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m[1]!);
    text = text.replaceAllMapped(
      RegExp(r'(?<!\w)\*([^*\n]+)\*(?!\w)'),
      (m) => m[1]!,
    );
    text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^>\s?', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^(\-|\+|\*)\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (m) => m[1]!,
    );
    text = text.replaceAll(RegExp(r'\[[A-Z][A-Za-z0-9]{2,}\]'), '');
    text = text.replaceAll(
      RegExp(r'^\s*(DEBUG|TRACE|VERBOSE|FIXME|TODO)\s*:.*$', multiLine: true),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'^(id|sessionId|messageId|debugLabel)[ \t]*:[ \t]*\S+[ \t]*$',
        caseSensitive: false,
        multiLine: true,
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'\b(coffee|dream|palm|tarot|msg|session|conv|reading|star)_[A-Za-z0-9-]+\b',
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
      ),
      '',
    );
    text = text.replaceAll(RegExp(r'\{[^{}]{0,240}\}'), '');
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    text = text.replaceAll(RegExp(r' *\n *'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }
}
