/// Message-relevant Oracle Core observation for OR - never a history dump.
library;

import '../../../core/l10n/l10n.dart';
import '../../personal_discovery/copy/personal_theme_copy.dart';
import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../../personal_discovery/services/discovery_or_context.dart';
import '../../personal_discovery/services/or_cross_discovery_chambers.dart';
import '../models/oracle_next_action.dart';
import 'oracle_next_action_eligibility.dart';
import 'oracle_or_deep_context.dart';
import 'oracle_or_privacy.dart';
import 'oracle_or_theme_match.dart';
import 'oracle_theme_evidence_builder.dart';

abstract final class OracleOrContext {
  OracleOrContext._();

  static const maxChars = 220;

  /// Compact OBSERVATION body (untagged). Null when nothing relevant.
  static String? forMessage(
    PersonalDiscoveryProfile profile,
    String userMessage, {
    OracleNextAction? nextAction,
    Set<String>? allowedSources,
    DateTime? now,
    bool deep = false,
  }) {
    final msg = userMessage.trim().toLowerCase();
    if (msg.isEmpty) return null;
    final clock = now ?? DateTime.now();
    final pick = _pick(
      profile,
      msg,
      nextAction: nextAction,
      allowedSources: allowedSources,
      now: clock,
    );
    if (pick == null) return null;
    final evidence = OracleThemeEvidenceBuilder.fromObservations(
      profile.observations,
      theme: pick.theme,
      allowedSources: allowedSources,
      max: deep ? 12 : 8,
    );
    if (evidence.length < OracleNextActionEligibility.minOccurrences) {
      return null;
    }
    final sources = {
      for (final e in evidence) e.sourceFeature,
    };
    if (sources.length < OracleNextActionEligibility.minSourceFeatures) {
      return null;
    }
    final themes = [pick.theme];
    final body = sources.length >= 2
        ? PersonalThemeCopy.crossModal(themes)
        : PersonalThemeCopy.recurring(themes);
    final areas = _areaBit(sources, deep: deep);
    final compare =
        deep ? OracleOrDeepContext.compareBit(evidence) : null;
    return _cap(
      [body, ?areas, ?compare, DiscoveryOrContext.instruction].join(' '),
      deep ? OracleOrDeepContext.maxChars : maxChars,
    );
  }

  static OracleOrThemeHit? _pick(
    PersonalDiscoveryProfile profile,
    String msg, {
    OracleNextAction? nextAction,
    Set<String>? allowedSources,
    required DateTime now,
  }) {
    if (nextAction != null &&
        nextAction.hasEvidence &&
        OracleOrThemeMatch.themeRelevant(nextAction.theme, msg)) {
      final allowed = [
        for (final s in nextAction.sourceFeatures)
          if (OracleOrPrivacy.allows(s, allowedSources)) s,
      ];
      if (allowed.length >= OracleNextActionEligibility.minSourceFeatures) {
        return OracleOrThemeHit(theme: nextAction.theme, score: 1000);
      }
    }
    final ranked = <OracleOrThemeHit>[];
    for (final insight in profile.crossInsights) {
      if (!OracleNextActionEligibility.insightQualifies(insight, now)) {
        continue;
      }
      final sources = [
        for (final s in insight.sources)
          if (OracleOrPrivacy.allows(s, allowedSources)) s,
      ];
      if (sources.length < OracleNextActionEligibility.minSourceFeatures) {
        continue;
      }
      if (!OracleOrThemeMatch.themeRelevant(insight.theme, msg) &&
          !sources.any((s) => OrCrossDiscoveryChambers.mentioned(s, msg))) {
        continue;
      }
      ranked.add(
        OracleOrThemeHit(
          theme: insight.theme,
          score: insight.discoveryCount + (sources.length * 3),
        ),
      );
    }
    if (ranked.isEmpty) return null;
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked.first;
  }

  static String? _areaBit(Set<String> sources, {required bool deep}) {
    final take = deep ? 5 : 3;
    final labels = [
      for (final s in sources.take(take)) OrCrossDiscoveryChambers.label(s),
    ].where((l) => l.isNotEmpty).toList();
    if (labels.length < 2) return null;
    return OraclyL10n.t('or.ctx.areas').replaceAll('{areas}', labels.join(', '));
  }

  static String _cap(String text, int limit) {
    final t = text.trim();
    if (t.length <= limit) return t;
    final cut = t.substring(0, limit);
    final space = cut.lastIndexOf(' ');
    return space > 140 ? cut.substring(0, space) : cut;
  }
}
