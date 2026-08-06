/// OR-1160 — Template resolution with versioning support.
library;

import '../models/prompt_template.dart';

class TemplateRegistry {
  TemplateRegistry({required List<PromptTemplate> templates})
      : _templates = List.unmodifiable(templates);

  final List<PromptTemplate> _templates;

  PromptTemplate resolve({
    required String id,
    String? version,
    String locale = 'tr',
  }) {
    final matches = _templates.where((t) => t.id == id).toList();
    if (matches.isEmpty) {
      throw TemplateNotFoundException(id);
    }
    if (version != null) {
      return matches.firstWhere(
        (t) => t.version == version,
        orElse: () => throw TemplateVersionNotFoundException(id, version),
      );
    }
    matches.sort((a, b) => _compareVersions(b.version, a.version));
    return matches.first;
  }

  List<PromptTemplate> byDomain(String domain) =>
      _templates.where((t) => t.domain == domain).toList();

  List<PromptTemplate> all() => _templates;

  int _compareVersions(String a, String b) {
    final pa = a.split('.').map(int.parse).toList();
    final pb = b.split('.').map(int.parse).toList();
    for (var i = 0; i < pa.length && i < pb.length; i++) {
      final cmp = pa[i].compareTo(pb[i]);
      if (cmp != 0) return cmp;
    }
    return pa.length.compareTo(pb.length);
  }
}

class TemplateNotFoundException implements Exception {
  TemplateNotFoundException(this.templateId);
  final String templateId;

  @override
  String toString() => 'Template not found: $templateId';
}

class TemplateVersionNotFoundException implements Exception {
  TemplateVersionNotFoundException(this.templateId, this.version);
  final String templateId;
  final String version;

  @override
  String toString() => 'Template version not found: $templateId@$version';
}
