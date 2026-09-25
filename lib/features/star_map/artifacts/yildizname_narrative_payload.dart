/// Typed Narrative V1 artifact payload — request + accepted result maps.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../narrative/request/yildizname_narrative_request.dart';
import '../narrative/result/yildizname_narrative_section.dart';
import '../narrative/result/yildizname_narrative_structured_result.dart';
import 'yildizname_artifact_canonical.dart';

abstract final class YildiznameNarrativePayload {
  YildiznameNarrativePayload._();

  static Map<String, dynamic> build({
    required YildiznameNarrativeRequest request,
    required YildiznameNarrativeStructuredResult result,
  }) =>
      {
        'request': request.toProviderJson(),
        'result': resultToMap(result),
      };

  static Map<String, dynamic> resultToMap(
    YildiznameNarrativeStructuredResult r,
  ) =>
      {
        'contractVersion': r.contractVersion,
        'languageCode': r.languageCode,
        'scope': r.scope.name,
        'summary': _block(r.summary),
        'sections': [
          for (final s in r.sections)
            {
              'kind': s.kind.wireName,
              'text': s.text,
              'factRefs': List<String>.from(s.factRefs),
              'themeRefs': List<String>.from(s.themeRefs),
            },
        ],
        'reflectionPrompt': _block(r.reflectionPrompt),
        'closingMessage': _block(r.closingMessage),
      };

  static Map<String, dynamic> _block(YildiznameNarrativeBlock b) => {
        'text': b.text,
        'factRefs': List<String>.from(b.factRefs),
        'themeRefs': List<String>.from(b.themeRefs),
      };

  static String resultContentDigest(Map<String, dynamic> payload) {
    final result = payload['result'];
    final encoded = YildiznameArtifactCanonical.encode(result);
    return sha256.convert(utf8.encode(encoded)).toString();
  }

  static Map<String, dynamic>? requestOf(Map<String, dynamic> payload) {
    final r = payload['request'];
    return r is Map ? Map<String, dynamic>.from(r) : null;
  }

  static Map<String, dynamic>? resultOf(Map<String, dynamic> payload) {
    final r = payload['result'];
    return r is Map ? Map<String, dynamic>.from(r) : null;
  }

  static Set<String> acceptedThemeRefs(Map<String, dynamic> payload) {
    final result = resultOf(payload);
    if (result == null) return {};
    final refs = <String>{};
    void take(Object? block) {
      if (block is! Map) return;
      final list = block['themeRefs'];
      if (list is List) {
        for (final e in list) {
          final s = e?.toString().trim() ?? '';
          if (s.isNotEmpty) refs.add(s);
        }
      }
    }

    take(result['summary']);
    take(result['reflectionPrompt']);
    take(result['closingMessage']);
    final sections = result['sections'];
    if (sections is List) {
      for (final s in sections) {
        take(s);
      }
    }
    return refs;
  }
}
