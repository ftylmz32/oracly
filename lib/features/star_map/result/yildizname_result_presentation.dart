/// Typed Yıldızname result presentation — the one contract the canonical
/// result screen renders.
///
/// Built by adapters (live legacy, artifact reopen, later Narrative live) and
/// handed to `StarMapReferenceResultScreen`. Widgets receive display-ready
/// semantics; they never read result maps, wire names, or stored fidelity.
library;

import 'package:flutter/foundation.dart';

import '../models/star_map_reading.dart';
import '../presentation/reference/star_map_result_section.dart';
import 'yildizname_fact_snapshot.dart';
import 'yildizname_result_chrome.dart';
import 'yildizname_result_types.dart';
import 'yildizname_scope_resolver.dart';

/// What the reading rests on — localized, evidence-derived, chrome only.
@immutable
final class YildiznameScopeDisclosure {
  const YildiznameScopeDisclosure({
    required this.evidence,
    required this.kicker,
    required this.body,
  });

  /// Resolves display copy for [evidence] in [languageCode] (default: app).
  factory YildiznameScopeDisclosure.of(
    YildiznameResolvedScope evidence, {
    String? languageCode,
  }) {
    return YildiznameScopeDisclosure(
      evidence: evidence,
      kicker: YildiznameResultChrome.scopeKicker(languageCode),
      body: YildiznameResultChrome.scopeBody(evidence, languageCode),
    );
  }

  final YildiznameResolvedScope evidence;

  /// Short heading — the question the note answers.
  final String kicker;

  /// One or two calm sentences. Never lists a layer the evidence lacks.
  final String body;

  YildiznameResultScope get scope => evidence.scope;

  @override
  bool operator ==(Object other) =>
      other is YildiznameScopeDisclosure &&
      other.evidence == evidence &&
      other.kicker == kicker &&
      other.body == body;

  @override
  int get hashCode => Object.hash(evidence, kicker, body);
}

@immutable
final class YildiznameResultPresentation {
  const YildiznameResultPresentation({
    required this.source,
    required this.scope,
    required this.title,
    required this.sections,
    this.planets = const [],
    this.scopeDisclosure,
    this.artifactId,
    this.createdAtUtc,
    this.chromeLanguage,
    this.factSnapshot = YildiznameFactSnapshot.empty,
  });

  /// Live legacy result — symbolic Sun-sign level material only.
  factory YildiznameResultPresentation.legacyLive({
    required String title,
    required List<StarMapResultSection> sections,
    List<StarMapPlanetInfluence> planets = const [],
    String? artifactId,
    DateTime? createdAtUtc,
    String? chromeLanguage,
  }) {
    final lang = YildiznameResultChrome.language(chromeLanguage);
    return YildiznameResultPresentation(
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
  }

  /// Pre-typed compatibility path: display-ready strings, NO scope claim.
  ///
  /// Exists only so the frozen Phase 7A pixel baselines keep exercising the
  /// shared chrome unchanged. Production must never use it (a firewall test
  /// scans lib/ for any other caller).
  factory YildiznameResultPresentation.unscoped({
    required String title,
    required List<StarMapResultSection> sections,
    List<StarMapPlanetInfluence> planets = const [],
    String? artifactId,
    DateTime? createdAtUtc,
  }) {
    return YildiznameResultPresentation(
      source: YildiznameResultSource.legacyLive,
      scope: YildiznameResultScope.legacy,
      title: title,
      sections: List.unmodifiable(sections),
      planets: List.unmodifiable(planets),
      artifactId: artifactId,
      createdAtUtc: createdAtUtc,
    );
  }

  final YildiznameResultSource source;
  final YildiznameResultScope scope;

  /// Display-ready title (localized product label or stored legacy title).
  final String title;

  /// Summary / chapter / reflection / closing — chrome titles, stored prose.
  final List<StarMapResultSection> sections;

  /// Legacy catalogue planets only. Narrative never carries them.
  final List<StarMapPlanetInfluence> planets;

  /// Null only on the test-only unscoped path.
  final YildiznameScopeDisclosure? scopeDisclosure;

  /// Durable artifact id — internal (favorite / share); never displayed.
  final String? artifactId;
  final DateTime? createdAtUtc;

  /// Language the chrome was resolved in (prose keeps its stored language).
  final String? chromeLanguage;

  /// Truthful natal facts projected from the STORED request, up to the
  /// resolved scope. Empty for legacy results and unproven evidence.
  final YildiznameFactSnapshot factSnapshot;

  bool get isHistoricalArtifact => source.isArtifact;

  /// Same presentation without the fact layer — the Phase 7B contract shape,
  /// kept so the phase-scoped 7B baselines stay comparable.
  YildiznameResultPresentation withoutFactSnapshot() =>
      YildiznameResultPresentation(
        source: source,
        scope: scope,
        title: title,
        sections: sections,
        planets: planets,
        scopeDisclosure: scopeDisclosure,
        artifactId: artifactId,
        createdAtUtc: createdAtUtc,
        chromeLanguage: chromeLanguage,
      );

  @override
  bool operator ==(Object other) {
    if (other is! YildiznameResultPresentation) return false;
    if (other.source != source ||
        other.scope != scope ||
        other.title != title ||
        other.scopeDisclosure != scopeDisclosure ||
        other.artifactId != artifactId ||
        other.createdAtUtc != createdAtUtc ||
        other.chromeLanguage != chromeLanguage ||
        other.factSnapshot != factSnapshot ||
        !listEquals(other.sections, sections) ||
        other.planets.length != planets.length) {
      return false;
    }
    for (var i = 0; i < planets.length; i++) {
      final a = planets[i];
      final b = other.planets[i];
      if (a.nameTr != b.nameTr ||
          a.influence != b.influence ||
          a.explanation != b.explanation ||
          a.polarity != b.polarity) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    source,
    scope,
    title,
    scopeDisclosure,
    artifactId,
    createdAtUtc,
    chromeLanguage,
    factSnapshot,
    Object.hashAll(sections),
    planets.length,
  );
}
