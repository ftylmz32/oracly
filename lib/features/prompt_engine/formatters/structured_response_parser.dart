/// OR-1160 — Parses raw AI text into structured output blocks.
library;

import 'output_format.dart';

class StructuredResponseParser {
  const StructuredResponseParser();

  StructuredPromptOutput parse(String rawText) {
    final blocks = <OutputBlock>[];
    final sections = _splitSections(rawText);

    for (final section in sections.entries) {
      final title = section.key;
      final content = section.value.trim();
      if (content.isEmpty) continue;

      final type = _mapTitleToType(title);
      if (type == OutputBlockType.list) {
        blocks.add(
          OutputBlock(
            type: type,
            title: title,
            content: content,
            items: _extractListItems(content),
          ),
        );
      } else {
        blocks.add(
          OutputBlock(
            type: type,
            title: title,
            content: content,
          ),
        );
      }
    }

    if (blocks.isEmpty && rawText.trim().isNotEmpty) {
      blocks.add(
        OutputBlock(
          type: OutputBlockType.markdown,
          content: rawText.trim(),
        ),
      );
    }

    return StructuredPromptOutput(blocks: blocks);
  }

  Map<String, String> _splitSections(String raw) {
    final result = <String, String>{};
    final pattern = RegExp(r'^##\s+(.+)$', multiLine: true);
    final matches = pattern.allMatches(raw).toList();

    if (matches.isEmpty) {
      result['İçerik'] = raw;
      return result;
    }

    for (var i = 0; i < matches.length; i++) {
      final title = matches[i].group(1)!.trim();
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : raw.length;
      result[title] = raw.substring(start, end);
    }
    return result;
  }

  OutputBlockType _mapTitleToType(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('özet') || lower.contains('summary')) {
      return OutputBlockType.summary;
    }
    if (lower.contains('tavsiye') || lower.contains('advice')) {
      return OutputBlockType.advice;
    }
    if (lower.contains('uyarı') || lower.contains('warning')) {
      return OutputBlockType.warning;
    }
    if (lower.contains('sembol') || lower.contains('liste')) {
      return OutputBlockType.list;
    }
    if (lower.contains('vurgu') || lower.contains('highlight')) {
      return OutputBlockType.highlight;
    }
    return OutputBlockType.section;
  }

  List<String> _extractListItems(String content) {
    return content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.startsWith('-') || line.startsWith('•'))
        .map((line) => line.replaceFirst(RegExp(r'^[-•]\s*'), ''))
        .where((line) => line.isNotEmpty)
        .toList();
  }
}
