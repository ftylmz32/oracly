/// Factory helpers for [YildiznameResultPresentation].
library;

import '../models/star_map_reading.dart';
import '../presentation/reference/star_map_result_section.dart';
import 'yildizname_result_actions_builder.dart';
import 'yildizname_result_chrome.dart';
import 'yildizname_result_presentation.dart';
import 'yildizname_result_types.dart';
import 'yildizname_scope_resolver.dart';

abstract final class YildiznameResultPresentationBuild {
  YildiznameResultPresentationBuild._();

  static YildiznameResultPresentation legacyLive({
    required String title,
    required List<StarMapResultSection> sections,
    List<StarMapPlanetInfluence> planets = const [],
    String? artifactId,
    DateTime? createdAtUtc,
    String? chromeLanguage,
  }) {
    final lang = YildiznameResultChrome.language(chromeLanguage);
    final base = YildiznameResultPresentation(
      source: YildiznameResultSource.legacyLive,
      scope: YildiznameResultScope.legacy,
      title: title,
      sections: List.unmodifiable(sections),
      planets: List.unmodifiable(planets),
      scopeDisclosure: YildiznameScopeDisclosure.of(
        YildiznameResolvedScope.legacy,
        languageCode: lang,
      ),
      artifactId: artifactId,
      createdAtUtc: createdAtUtc,
      chromeLanguage: lang,
    );
    return base.withActions(
      YildiznameResultActionsBuilder.build(presentation: base),
    );
  }

  static YildiznameResultPresentation unscoped({
    required String title,
    required List<StarMapResultSection> sections,
    List<StarMapPlanetInfluence> planets = const [],
    String? artifactId,
    DateTime? createdAtUtc,
  }) {
    final base = YildiznameResultPresentation(
      source: YildiznameResultSource.legacyLive,
      scope: YildiznameResultScope.legacy,
      title: title,
      sections: List.unmodifiable(sections),
      planets: List.unmodifiable(planets),
      artifactId: artifactId,
      createdAtUtc: createdAtUtc,
      forensicLegacyActionOrder: true,
    );
    return base.withActions(
      YildiznameResultActionsBuilder.build(presentation: base),
    );
  }
}
