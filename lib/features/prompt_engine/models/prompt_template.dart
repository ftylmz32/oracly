/// OR-1160 — Versioned prompt template with sections and localization.
library;

import 'prompt_variable.dart';

class PromptTemplate {
  const PromptTemplate({
    required this.id,
    required this.version,
    required this.domain,
    required this.systemBody,
    required this.userBody,
    this.sections = const {},
    this.localizations = const {},
    this.variables = const [],
    this.outputFormatId,
    this.maxPromptLength = 12000,
    this.expectedOutputTokens = 800,
  });

  final String id;
  final String version;
  final String domain;
  final String systemBody;
  final String userBody;
  final Map<String, String> sections;
  final Map<String, Map<String, String>> localizations;
  final List<PromptVariable> variables;
  final String? outputFormatId;
  final int maxPromptLength;
  final int expectedOutputTokens;

  String? localization(String locale, String key) {
    final exact = localizations[locale]?[key];
    if (exact != null) return exact;
    if (localizations.containsKey(locale)) return null;
    return localizations['tr']?[key];
  }

  PromptTemplate copyWith({
    String? version,
    Map<String, String>? sections,
    Map<String, Map<String, String>>? localizations,
  }) {
    return PromptTemplate(
      id: id,
      version: version ?? this.version,
      domain: domain,
      systemBody: systemBody,
      userBody: userBody,
      sections: sections ?? this.sections,
      localizations: localizations ?? this.localizations,
      variables: variables,
      outputFormatId: outputFormatId,
      maxPromptLength: maxPromptLength,
      expectedOutputTokens: expectedOutputTokens,
    );
  }
}
