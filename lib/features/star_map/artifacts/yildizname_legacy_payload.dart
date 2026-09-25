/// Typed legacy-local artifact payload helpers.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/star_map_reading.dart';
import '../presentation/reference/star_map_result_section.dart';
import 'yildizname_artifact_canonical.dart';
import 'yildizname_legacy_section_kind.dart';

abstract final class YildiznameLegacyPayload {
  YildiznameLegacyPayload._();

  static Map<String, dynamic> build({
    required String title,
    required List<StarMapResultSection> sections,
    required YildiznameLegacySectionKind sectionKind,
    List<StarMapPlanetInfluence> planets = const [],
    String? sunSignId,
    String? dayKey,
  }) =>
      {
        'title': title,
        'sectionKind': sectionKind.wireName,
        'sunSignId': ?sunSignId,
        'dayKey': ?dayKey,
        'sections': [
          for (final s in sections) {'title': s.title, 'body': s.body},
        ],
        'planets': [
          for (final p in planets)
            {
              'nameTr': p.nameTr,
              'influence': p.influence,
              'explanation': p.explanation,
              'polarity': p.polarity.name,
            },
        ],
      };

  static String contentDigest(Map<String, dynamic> payload) {
    final encoded = YildiznameArtifactCanonical.encode({
      'title': payload['title'],
      'sections': payload['sections'],
      'planets': payload['planets'],
      'sectionKind': payload['sectionKind'],
      'sunSignId': payload['sunSignId'],
    });
    return sha256.convert(utf8.encode(encoded)).toString();
  }

  static String? titleOf(Map<String, dynamic> payload) =>
      payload['title']?.toString();

  static List<StarMapResultSection> sectionsOf(Map<String, dynamic> payload) {
    final raw = payload['sections'];
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map)
          StarMapResultSection(
            title: '${e['title'] ?? ''}',
            body: '${e['body'] ?? ''}',
          ),
    ];
  }

  static List<StarMapPlanetInfluence> planetsOf(Map<String, dynamic> payload) {
    final raw = payload['planets'];
    if (raw is! List) return const [];
    final out = <StarMapPlanetInfluence>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final polarity = StarMapPolarity.values.where(
        (p) => p.name == '${e['polarity']}',
      );
      out.add(
        StarMapPlanetInfluence(
          nameTr: '${e['nameTr'] ?? ''}',
          influence: '${e['influence'] ?? ''}',
          explanation: '${e['explanation'] ?? ''}',
          polarity: polarity.isEmpty
              ? StarMapPolarity.balanced
              : polarity.first,
        ),
      );
    }
    return out;
  }
}
