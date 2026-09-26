/// Localized result chrome — explicit mappings only.
///
/// Chrome localizes; stored prose never does. Labels are never derived from
/// enum names, wire names, or identifiers, and an unknown kind falls back to
/// neutral chapter chrome instead of exposing a raw identifier.
library;

import '../../../core/l10n/l10n.dart';
import '../narrative/result/yildizname_section_kind.dart';
import 'yildizname_result_types.dart';
import 'yildizname_scope_resolver.dart';

abstract final class YildiznameResultChrome {
  YildiznameResultChrome._();

  /// Chrome language — the app's current language unless a test pins one.
  static String language([String? code]) =>
      AppLocale.normalize(code ?? OraclyL10n.code);

  static String _t(String key, String languageCode) =>
      OraclyL10n.t(key, languageCode: languageCode);

  /// Product label — the app's own localized name for Yıldızname.
  static String productTitle([String? languageCode]) =>
      _t(L10nKeys.starMap, language(languageCode));

  /// Title for a non-chapter role (summary / reflection / closing).
  static String roleTitle(YildiznameSectionRole role, [String? languageCode]) {
    final lang = language(languageCode);
    return switch (role) {
      YildiznameSectionRole.summary => _t('star.result.role.summary', lang),
      YildiznameSectionRole.reflection => _t(
        'star.result.role.reflection',
        lang,
      ),
      YildiznameSectionRole.closing => _t('star.result.role.closing', lang),
      YildiznameSectionRole.chapter => neutralChapterTitle(lang),
    };
  }

  static String neutralChapterTitle([String? languageCode]) =>
      _t('star.result.chapter.neutral', language(languageCode));

  /// Chapter title for a supported section kind. `null` (unknown / future
  /// kind) yields neutral chrome — never the raw identifier.
  static String chapterTitle(
    YildiznameSectionKind? kind, [
    String? languageCode,
  ]) {
    final lang = language(languageCode);
    if (kind == null) return neutralChapterTitle(lang);
    final key = switch (kind) {
      YildiznameSectionKind.coreIdentity => 'star.result.chapter.identity',
      YildiznameSectionKind.emotionalWorld => 'star.result.chapter.emotional',
      YildiznameSectionKind.mindAndExpression => 'star.result.chapter.mind',
      YildiznameSectionKind.relationshipsAndValues =>
        'star.result.chapter.relationships',
      YildiznameSectionKind.driveAndGrowth => 'star.result.chapter.drive',
      YildiznameSectionKind.anglesAndHouses => 'star.result.chapter.angles',
      YildiznameSectionKind.patternsAndTensions =>
        'star.result.chapter.patterns',
      YildiznameSectionKind.strengthsAndResources =>
        'star.result.chapter.strengths',
      YildiznameSectionKind.archiveEcho => 'star.result.chapter.echo',
      YildiznameSectionKind.practicalReflection =>
        'star.result.chapter.practice',
    };
    return _t(key, lang);
  }

  static String scopeKicker([String? languageCode]) =>
      _t('star.result.scope.kicker', language(languageCode));

  /// Artifact reopen provenance label — never used for live readings.
  static String historicalLabel([String? languageCode]) =>
      _t('star.result.historical.label', language(languageCode));

  /// Continuity archive heading — chrome only.
  static String continuityHeading([String? languageCode]) =>
      _t('star.result.continuity.heading', language(languageCode));

  /// Continuity supporting sentence — chrome only; never invents dates/counts.
  static String continuityBody([String? languageCode]) =>
      _t('star.result.continuity.body', language(languageCode));

  /// What the reading rests on — never lists a layer the evidence lacks, and
  /// FULL never promises every possible layer.
  static String scopeBody(
    YildiznameResolvedScope resolved, [
    String? languageCode,
  ]) {
    final lang = language(languageCode);
    final key = switch (resolved.scope) {
      YildiznameResultScope.legacy => 'star.result.scope.legacy',
      YildiznameResultScope.reduced => 'star.result.scope.reduced',
      YildiznameResultScope.full =>
        resolved.fullLayersComplete
            ? 'star.result.scope.full'
            : 'star.result.scope.full_partial',
    };
    return _t(key, lang);
  }
}
