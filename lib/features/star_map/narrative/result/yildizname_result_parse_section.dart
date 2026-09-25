/// Section parse helper for Narrative V1 results.
library;

import '../versions.dart';
import 'yildizname_narrative_section.dart';
import 'yildizname_result_error.dart';
import 'yildizname_result_parse_parts.dart';
import 'yildizname_section_kind.dart';

abstract final class YildiznameResultParseSection {
  YildiznameResultParseSection._();

  static YildiznameNarrativeSection parse(Object? raw) {
    if (raw is! Map) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.schema,
        'section',
      );
    }
    final map = Map<String, dynamic>.from(raw);
    YildiznameResultParseParts.rejectUnknown(
      map,
      YildiznameResultParseParts.allowedSection,
    );
    YildiznameResultParseParts.requireKeys(
      map,
      YildiznameResultParseParts.allowedSection,
    );
    final kindRaw = map['kind'];
    if (kindRaw is! String) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.schema,
        'kind',
      );
    }
    final kind = YildiznameSectionKind.tryParse(kindRaw);
    if (kind == null) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.unknownKind,
        kindRaw,
      );
    }
    return YildiznameNarrativeSection(
      kind: kind,
      text: YildiznameResultParseParts.requireString(
        map,
        'text',
        min: kYildiznameMinSectionChars,
        max: kYildiznameMaxSectionChars,
      ),
      factRefs: YildiznameResultParseParts.requireStringList(map, 'factRefs'),
      themeRefs: YildiznameResultParseParts.requireStringList(map, 'themeRefs'),
    );
  }
}
