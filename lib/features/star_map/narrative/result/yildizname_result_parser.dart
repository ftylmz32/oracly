/// Strict client parser for Yıldızname Narrative V1 structured results.
library;

import '../request/yildizname_narrative_scope.dart';
import '../versions.dart';
import 'yildizname_narrative_section.dart';
import 'yildizname_narrative_structured_result.dart';
import 'yildizname_result_error.dart';
import 'yildizname_result_parse_parts.dart';
import 'yildizname_result_parse_section.dart';
import 'yildizname_section_kind.dart';

abstract final class YildiznameResultParser {
  YildiznameResultParser._();

  static YildiznameNarrativeStructuredResult parse(Map<String, dynamic> data) {
    YildiznameResultParseParts.rejectUnknown(
      data,
      YildiznameResultParseParts.allowedRoot,
    );
    YildiznameResultParseParts.requireKeys(
      data,
      YildiznameResultParseParts.allowedRoot,
    );

    final version = data['contractVersion'];
    if (version is! int || version != kYildiznameResultContractVersion) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.version,
        '$version',
      );
    }

    final languageCode = YildiznameResultParseParts.requireString(
      data,
      'languageCode',
      min: 2,
      max: kYildiznameMaxLanguageCodeChars,
    );
    if (!kYildiznameLocales.contains(languageCode)) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.locale,
        languageCode,
      );
    }

    final scopeRaw = data['scope'];
    if (scopeRaw is! String) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.schema,
        'scope',
      );
    }
    YildiznameNarrativeScope? scope;
    for (final s in YildiznameNarrativeScope.values) {
      if (s.name == scopeRaw) {
        scope = s;
        break;
      }
    }
    if (scope == null) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.scope,
        scopeRaw,
      );
    }

    final sectionsRaw = data['sections'];
    if (sectionsRaw is! List ||
        sectionsRaw.isEmpty ||
        sectionsRaw.length > kYildiznameMaxSections) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.bounds,
        'sections',
      );
    }
    final kinds = <YildiznameSectionKind>{};
    final sections = <YildiznameNarrativeSection>[];
    for (final raw in sectionsRaw) {
      final s = YildiznameResultParseSection.parse(raw);
      if (!kinds.add(s.kind)) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.duplicate,
          s.kind.wireName,
        );
      }
      sections.add(s);
    }

    return YildiznameNarrativeStructuredResult(
      contractVersion: version,
      languageCode: languageCode,
      scope: scope,
      summary: YildiznameResultParseParts.parseBlock(
        data['summary'],
        minText: kYildiznameMinSummaryChars,
        maxText: kYildiznameMaxSummaryChars,
      ),
      sections: sections,
      reflectionPrompt: YildiznameResultParseParts.parseBlock(
        data['reflectionPrompt'],
        minText: 10,
        maxText: kYildiznameMaxReflectionChars,
      ),
      closingMessage: YildiznameResultParseParts.parseBlock(
        data['closingMessage'],
        minText: 10,
        maxText: kYildiznameMaxClosingChars,
      ),
    );
  }
}
