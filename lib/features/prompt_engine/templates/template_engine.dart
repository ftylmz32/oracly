/// OR-1160 — Parses and renders template strings.
library;

import '../models/prompt_template.dart';

class TemplateRenderResult {
  const TemplateRenderResult({
    required this.text,
    this.unresolvedVariables = const [],
  });

  final String text;
  final List<String> unresolvedVariables;
}

class TemplateEngine {
  const TemplateEngine();

  TemplateRenderResult renderSystem(
    PromptTemplate template,
    Map<String, dynamic> variables,
    String locale,
  ) =>
      _render(template.systemBody, template, variables, locale);

  TemplateRenderResult renderUser(
    PromptTemplate template,
    Map<String, dynamic> variables,
    String locale,
  ) =>
      _render(template.userBody, template, variables, locale);

  TemplateRenderResult renderSection(
    String sectionBody,
    PromptTemplate template,
    Map<String, dynamic> variables,
    String locale,
  ) =>
      _render(sectionBody, template, variables, locale);

  TemplateRenderResult _render(
    String body,
    PromptTemplate template,
    Map<String, dynamic> variables,
    String locale,
  ) {
    var output = body;
    final unresolved = <String>{};

    for (var pass = 0; pass < 8; pass++) {
      final before = output;

      output = _renderSections(output, template, variables, locale, unresolved);
      output = _renderConditionals(output, variables);
      output = _renderLocalizations(output, template, locale, unresolved);
      output = _renderVariables(output, variables, unresolved);

      if (output == before) break;
    }

    return TemplateRenderResult(
      text: output.trim(),
      unresolvedVariables: unresolved.toList(),
    );
  }

  String _renderSections(
    String input,
    PromptTemplate template,
    Map<String, dynamic> variables,
    String locale,
    Set<String> unresolved,
  ) {
    final pattern = RegExp(r'\{\{>\s*([a-zA-Z0-9_.-]+)\s*\}\}');
    return input.replaceAllMapped(pattern, (match) {
      final id = match.group(1)!;
      final section = template.sections[id];
      if (section == null) {
        unresolved.add('section:$id');
        return '';
      }
      return _render(section, template, variables, locale).text;
    });
  }

  String _renderConditionals(String input, Map<String, dynamic> variables) {
    final ifPattern = RegExp(
      r'\{\{#if\s+([a-zA-Z0-9_.-]+)\s*\}\}([\s\S]*?)\{\{/if\}\}',
    );
    var output = input.replaceAllMapped(ifPattern, (match) {
      final key = match.group(1)!;
      final body = match.group(2)!;
      return _isTruthy(variables[key]) ? body : '';
    });

    final unlessPattern = RegExp(
      r'\{\{\^if\s+([a-zA-Z0-9_.-]+)\s*\}\}([\s\S]*?)\{\{/if\}\}',
    );
    output = output.replaceAllMapped(unlessPattern, (match) {
      final key = match.group(1)!;
      final body = match.group(2)!;
      return _isTruthy(variables[key]) ? '' : body;
    });

    return output;
  }

  String _renderLocalizations(
    String input,
    PromptTemplate template,
    String locale,
    Set<String> unresolved,
  ) {
    final pattern = RegExp(r'\{\{@locale\.([a-zA-Z0-9_.-]+)\s*\}\}');
    return input.replaceAllMapped(pattern, (match) {
      final key = match.group(1)!;
      final value = template.localization(locale, key);
      if (value == null) unresolved.add('locale:$key');
      return value ?? '';
    });
  }

  String _renderVariables(
    String input,
    Map<String, dynamic> variables,
    Set<String> unresolved,
  ) {
    final pattern = RegExp(r'\{\{\s*([a-zA-Z0-9_.-]+)\s*\}\}');
    return input.replaceAllMapped(pattern, (match) {
      final key = match.group(1)!;
      if (!variables.containsKey(key) || variables[key] == null) {
        unresolved.add(key);
        return '';
      }
      return _stringify(variables[key]);
    });
  }

  bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  String _stringify(dynamic value) {
    if (value is List) {
      return value.map(_stringify).join(', ');
    }
    return value.toString();
  }
}
