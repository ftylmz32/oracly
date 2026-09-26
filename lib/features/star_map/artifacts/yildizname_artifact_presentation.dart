/// Projects stored artifacts (and, later, live Narrative results) into the
/// typed [YildiznameResultPresentation] the canonical result screen renders.
///
/// Prose comes from the stored result exactly as accepted. Chrome (titles,
/// scope disclosure) localizes; scope is resolved from stored evidence only —
/// never by recalculating astronomy, calling a provider, or mutating the
/// artifact.
library;

import '../narrative/request/yildizname_narrative_request.dart';
import '../narrative/request/yildizname_narrative_scope.dart';
import '../narrative/result/yildizname_narrative_structured_result.dart';
import '../narrative/result/yildizname_section_kind.dart';
import '../presentation/reference/star_map_result_section.dart';
import '../result/yildizname_fact_projector.dart';
import '../result/yildizname_result_actions_builder.dart';
import '../result/yildizname_result_chrome.dart';
import '../result/yildizname_result_presentation.dart';
import '../result/yildizname_result_types.dart';
import '../result/yildizname_scope_resolver.dart';
import 'yildizname_artifact.dart';
import 'yildizname_artifact_source.dart';
import 'yildizname_legacy_payload.dart';
import 'yildizname_narrative_payload.dart';

abstract final class YildiznameArtifactPresentation {
  YildiznameArtifactPresentation._();

  /// Typed projection of a stored artifact.
  ///
  /// [chromeLocale] pins the chrome language (tests); by default the app's
  /// current language. The stored result language never changes.
  static YildiznameResultPresentation of(
    YildiznameArtifact artifact, {
    String? chromeLocale,
  }) {
    final lang = YildiznameResultChrome.language(chromeLocale);
    if (artifact.source == YildiznameArtifactSource.legacyLocal) {
      return _withActions(_legacyArtifact(artifact, lang));
    }
    return _withActions(
      _narrative(
        source: YildiznameResultSource.narrativeArtifact,
        payload: artifact.payload,
        artifactScope: artifact.scope,
        artifactFidelity: artifact.fidelity,
        artifactId: artifact.id,
        createdAtUtc: artifact.createdAtUtc,
        lang: lang,
      ),
    );
  }

  /// Live accepted Narrative result — same projection as an artifact reopen,
  /// so Phase 8 needs no second screen or second chrome path.
  static YildiznameResultPresentation narrativeLive({
    required YildiznameNarrativeRequest request,
    required YildiznameNarrativeStructuredResult result,
    String? artifactId,
    DateTime? createdAtUtc,
    String? chromeLocale,
  }) {
    return _withActions(
      _narrative(
        source: YildiznameResultSource.narrativeLive,
        payload: YildiznameNarrativePayload.build(
          request: request,
          result: result,
        ),
        artifactScope: request.scope.wireName,
        artifactFidelity: request.fidelity,
        artifactId: artifactId,
        createdAtUtc: createdAtUtc,
        lang: YildiznameResultChrome.language(chromeLocale),
      ),
    );
  }

  static YildiznameResultPresentation _withActions(
    YildiznameResultPresentation base,
  ) =>
      base.withActions(
        YildiznameResultActionsBuilder.build(presentation: base),
      );

  static YildiznameResultPresentation _legacyArtifact(
    YildiznameArtifact artifact,
    String lang,
  ) {
    final stored = YildiznameLegacyPayload.titleOf(artifact.payload)?.trim();
    return YildiznameResultPresentation(
      source: YildiznameResultSource.legacyArtifact,
      scope: YildiznameResultScope.legacy,
      title: (stored == null || stored.isEmpty)
          ? YildiznameResultChrome.productTitle(lang)
          : stored,
      sections: List.unmodifiable(
        YildiznameLegacyPayload.sectionsOf(artifact.payload),
      ),
      planets: List.unmodifiable(
        YildiznameLegacyPayload.planetsOf(artifact.payload),
      ),
      scopeDisclosure: YildiznameScopeDisclosure.of(
        YildiznameResolvedScope.legacy,
        languageCode: lang,
      ),
      artifactId: artifact.id,
      createdAtUtc: artifact.createdAtUtc,
      chromeLanguage: lang,
    );
  }

  static YildiznameResultPresentation _narrative({
    required YildiznameResultSource source,
    required Map<String, dynamic> payload,
    required String? artifactScope,
    required String? artifactFidelity,
    required String? artifactId,
    required DateTime? createdAtUtc,
    required String lang,
  }) {
    final request = YildiznameNarrativePayload.requestOf(payload);
    final result = YildiznameNarrativePayload.resultOf(payload);
    final resolved = YildiznameScopeResolver.resolveNarrative(
      artifactScope: artifactScope,
      artifactFidelity: artifactFidelity,
      request: request,
      result: result,
    );
    return YildiznameResultPresentation(
      source: source,
      scope: resolved.scope,
      title: YildiznameResultChrome.productTitle(lang),
      sections: List.unmodifiable(
        result == null
            ? const <StarMapResultSection>[]
            : _sections(result, lang),
      ),
      scopeDisclosure: YildiznameScopeDisclosure.of(
        resolved,
        languageCode: lang,
      ),
      artifactId: artifactId,
      createdAtUtc: createdAtUtc,
      chromeLanguage: lang,
      // Stored request only, capped by the resolved scope — never the current
      // profile, a recalculation, or the prose.
      factSnapshot: YildiznameFactProjector.project(
        resolved: resolved,
        request: request,
        languageCode: lang,
      ),
    );
  }

  /// Body = stored prose only, exactly as accepted. Never exposes factRefs /
  /// themeRefs; titles are localized chrome, never wire or enum names.
  static List<StarMapResultSection> _sections(
    Map<String, dynamic> result,
    String lang,
  ) {
    final out = <StarMapResultSection>[];
    void block(Object? raw, YildiznameSectionRole role) {
      if (raw is! Map) return;
      final text = '${raw['text'] ?? ''}';
      if (text.trim().isEmpty) return;
      out.add(
        StarMapResultSection(
          title: YildiznameResultChrome.roleTitle(role, lang),
          body: text,
          role: role,
        ),
      );
    }

    block(result['summary'], YildiznameSectionRole.summary);
    final rawSections = result['sections'];
    if (rawSections is List) {
      for (final s in rawSections) {
        if (s is! Map) continue;
        final text = '${s['text'] ?? ''}';
        if (text.trim().isEmpty) continue;
        out.add(
          StarMapResultSection(
            title: YildiznameResultChrome.chapterTitle(
              YildiznameSectionKind.tryParse('${s['kind'] ?? ''}'),
              lang,
            ),
            body: text,
            role: YildiznameSectionRole.chapter,
          ),
        );
      }
    }
    block(result['reflectionPrompt'], YildiznameSectionRole.reflection);
    block(result['closingMessage'], YildiznameSectionRole.closing);
    return out;
  }

  static String summaryQuote(YildiznameArtifact artifact) {
    final p = of(artifact);
    for (final s in p.sections) {
      if (s.body.trim().isNotEmpty) return s.body.trim();
    }
    return p.title;
  }
}
