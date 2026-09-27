/// Strict parse helpers for Narrative V1 result maps (part A).
library;

import '../versions.dart';
import 'yildizname_narrative_section.dart';
import 'yildizname_result_error.dart';

abstract final class YildiznameResultParseParts {
  YildiznameResultParseParts._();

  static const allowedRoot = {
    'contractVersion',
    'languageCode',
    'scope',
    'summary',
    'sections',
    'reflectionPrompt',
    'closingMessage',
  };

  static const allowedBlock = {'text', 'factRefs', 'themeRefs'};
  static const allowedSection = {'kind', 'text', 'factRefs', 'themeRefs'};

  static void rejectUnknown(Map<String, dynamic> map, Set<String> allowed) {
    for (final k in map.keys) {
      if (!allowed.contains(k)) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.unknownKey,
          k,
        );
      }
    }
  }

  static void requireKeys(Map<String, dynamic> map, Set<String> required) {
    for (final k in required) {
      if (!map.containsKey(k)) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.schema,
          'missing:$k',
        );
      }
    }
  }

  static String requireString(
    Map<String, dynamic> map,
    String key, {
    required int min,
    required int max,
  }) {
    final v = map[key];
    if (v is! String) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.schema,
        'type:$key',
      );
    }
    final t = v.trim();
    if (t.length < min || t.length > max) {
      throw YildiznameResultException(YildiznameResultErrorKind.bounds, key);
    }
    return t;
  }

  /// Frozen `reflectionPrompt`: `null` OR a non-empty bounded string.
  /// A block/map is NOT the provider contract and is rejected.
  static String? optionalString(
    Map<String, dynamic> map,
    String key, {
    required int max,
  }) {
    if (map[key] == null) return null;
    return requireString(map, key, min: 1, max: max);
  }

  /// Backend enforces `factRefs` and `themeRefs` with SEPARATE count and
  /// per-string-length ceilings (`maxFactRefsPerBlock`/`maxFactRefChars` vs
  /// `maxThemeRefsPerBlock`/`maxThemeRefChars`); [key] selects the matching
  /// pair so the two can never be collapsed into one incompatible limit.
  static List<String> requireStringList(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v is! List) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.schema,
        'type:$key',
      );
    }
    final maxCount = key == 'themeRefs'
        ? kYildiznameMaxThemeRefsPerBlock
        : kYildiznameMaxFactRefsPerBlock;
    final maxChars = key == 'themeRefs'
        ? kYildiznameMaxThemeRefChars
        : kYildiznameMaxFactRefChars;
    if (v.length > maxCount) {
      throw YildiznameResultException(YildiznameResultErrorKind.bounds, key);
    }
    final out = <String>[];
    final seen = <String>{};
    for (final e in v) {
      if (e is! String || e.isEmpty || e.length > maxChars) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.schema,
          'ref:$key',
        );
      }
      if (!seen.add(e)) {
        throw YildiznameResultException(YildiznameResultErrorKind.duplicate, e);
      }
      out.add(e);
    }
    return out;
  }

  static YildiznameNarrativeBlock parseBlock(
    Object? raw, {
    required int minText,
    required int maxText,
  }) {
    if (raw is! Map) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.schema,
        'block',
      );
    }
    final map = Map<String, dynamic>.from(raw);
    rejectUnknown(map, allowedBlock);
    requireKeys(map, allowedBlock);
    return YildiznameNarrativeBlock(
      text: requireString(map, 'text', min: minText, max: maxText),
      factRefs: requireStringList(map, 'factRefs'),
      themeRefs: requireStringList(map, 'themeRefs'),
    );
  }
}
