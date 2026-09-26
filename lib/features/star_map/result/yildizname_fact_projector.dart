/// Truthful natal fact projection from the STORED structured request.
///
/// Rules (every one can only REMOVE a fact, never add one):
/// * Facts come from the stored request of that exact reading — never from
///   prose, themes, the current profile, or a recalculation.
/// * The already-resolved scope is the CEILING: rich fields found under a
///   lighter resolved scope are ignored.
/// * `omittedLayers` contradictions were already applied by the resolver
///   (`hasAscendant` / `hasMidheaven` / `hasHouses` / `hasAspects`).
/// * Missing, unknown, malformed, contradictory or untrusted facts vanish —
///   no placeholder, no raw identifier, no `0°`.
library;

import 'dart:math' as math;

import 'yildizname_fact_chrome.dart';
import 'yildizname_fact_snapshot.dart';
import 'yildizname_result_chrome.dart';
import 'yildizname_result_types.dart';
import 'yildizname_scope_resolver.dart';

abstract final class YildiznameFactProjector {
  YildiznameFactProjector._();

  /// Editorial cap: the deeper layer shows the tightest aspects only.
  static const int maxAspects = 5;

  static YildiznameFactSnapshot project({
    required YildiznameResolvedScope resolved,
    required Map<String, dynamic>? request,
    String? languageCode,
  }) {
    if (request == null || resolved.scope == YildiznameResultScope.legacy) {
      return YildiznameFactSnapshot.empty;
    }
    final lang = YildiznameResultChrome.language(languageCode);
    final full = resolved.scope == YildiznameResultScope.full;

    final placements = _placements(request, resolved, full, lang);
    final angles = full ? _angles(request, resolved, lang) : const {};
    final byBody = {...placements, ...angles};

    List<YildiznameDisplayFact> group(YildiznameFactGroup g) => [
      for (final s in YildiznameFactChrome.order)
        if (byBody[s] != null && byBody[s]!.group == g) byBody[s]!,
    ];

    final aspects = full && resolved.hasAspects
        ? _aspects(request, placements.keys.toSet(), lang)
        : const <YildiznameDisplayAspect>[];
    final balances = full
        ? _balances(request, lang)
        : const <YildiznameDisplayBalance>[];

    final snapshot = YildiznameFactSnapshot(
      title: YildiznameFactChrome.title(lang),
      moreLabel: YildiznameFactChrome.moreLabel(lang),
      primary: group(YildiznameFactGroup.primary),
      secondary: group(YildiznameFactGroup.secondary),
      outer: group(YildiznameFactGroup.outer),
      outerLabel: YildiznameFactChrome.outerLabel(lang),
      aspects: aspects,
      aspectsLabel: YildiznameFactChrome.aspectsLabel(lang),
      balances: balances,
    );
    return snapshot.isEmpty ? YildiznameFactSnapshot.empty : snapshot;
  }

  // -- placements -------------------------------------------------------------

  static Map<YildiznameFactSubject, YildiznameDisplayFact> _placements(
    Map<String, dynamic> request,
    YildiznameResolvedScope resolved,
    bool full,
    String lang,
  ) {
    final raw = _maps(request['placements']);
    // A body stated twice is contradictory evidence — drop it entirely.
    final seen = <YildiznameFactSubject, int>{};
    for (final p in raw) {
      final s = YildiznameFactChrome.bodyOf(p['body']);
      if (s != null) seen[s] = (seen[s] ?? 0) + 1;
    }

    final out = <YildiznameFactSubject, YildiznameDisplayFact>{};
    for (final p in raw) {
      final subject = YildiznameFactChrome.bodyOf(p['body']);
      if (subject == null || seen[subject] != 1) continue;
      if (!_refMatches(p['factRef'], 'placement', p['body'])) continue;
      final sign = p['sign'];
      if (!YildiznameFactChrome.isSign(sign)) continue;

      final certainty = p['certainty'];
      final exact = full && certainty == 'exact';
      final trusted = exact || certainty == 'intervalStable';
      if (!trusted) continue; // ambiguous / unavailable / unsupported / unknown

      final parts = <String>[];
      if (exact) {
        final degree = _degree(p['degreeWithinSign']);
        if (degree != null) parts.add('$degree°');
        if (resolved.hasHouses) {
          final house = _house(p['house']);
          if (house != null) {
            parts.add(YildiznameFactChrome.houseLabel(house, lang));
          }
        }
        if (p['retrograde'] == true &&
            YildiznameFactChrome.canBeRetrograde(subject)) {
          parts.add(YildiznameFactChrome.retrogradeLabel(lang));
        }
      }
      out[subject] = YildiznameDisplayFact(
        subject: subject,
        group: YildiznameFactChrome.groupOf(subject),
        label: YildiznameFactChrome.subjectLabel(subject, lang),
        value: YildiznameFactChrome.signLabel(sign as String, lang),
        detail: parts.isEmpty ? null : parts.join(' · '),
      );
    }
    return out;
  }

  // -- angles (FULL only) -----------------------------------------------------

  static Map<YildiznameFactSubject, YildiznameDisplayFact> _angles(
    Map<String, dynamic> request,
    YildiznameResolvedScope resolved,
    String lang,
  ) {
    final raw = _maps(request['angles']);
    final out = <YildiznameFactSubject, YildiznameDisplayFact>{};
    void take(YildiznameFactSubject subject, bool allowed) {
      if (!allowed) return;
      final matches = [
        for (final a in raw)
          if (_angleSubject(a) == subject) a,
      ];
      if (matches.length != 1) return; // missing or contradictory
      final a = matches.single;
      if (a['certainty'] != 'exact') return;
      final sign = a['sign'];
      if (!YildiznameFactChrome.isSign(sign)) return;
      final degree = _degree(a['degreeWithinSign']);
      out[subject] = YildiznameDisplayFact(
        subject: subject,
        group: YildiznameFactGroup.primary,
        label: YildiznameFactChrome.subjectLabel(subject, lang),
        value: YildiznameFactChrome.signLabel(sign as String, lang),
        detail: degree == null ? null : '$degree°',
      );
    }

    take(YildiznameFactSubject.ascendant, resolved.hasAscendant);
    take(YildiznameFactSubject.midheaven, resolved.hasMidheaven);
    return out;
  }

  /// Angle identity from `kind` and the `angle.<kind>` factRef; if the two
  /// disagree the fact is contradictory and identifies as nothing.
  static YildiznameFactSubject? _angleSubject(Map<String, dynamic> fact) {
    final byKind = YildiznameFactChrome.angleOf(fact['kind']);
    final ref = fact['factRef'];
    final byRef = ref is String && ref.startsWith('angle.')
        ? YildiznameFactChrome.angleOf(ref.substring('angle.'.length))
        : null;
    if (byKind != null && byRef != null && byKind != byRef) return null;
    return byKind ?? byRef;
  }

  // -- aspects (FULL only) ----------------------------------------------------

  static List<YildiznameDisplayAspect> _aspects(
    Map<String, dynamic> request,
    Set<YildiznameFactSubject> displayedBodies,
    String lang,
  ) {
    final rows =
        <
          ({int a, int b, int type, double orb, YildiznameDisplayAspect view})
        >[];
    final seen = <String>{};
    for (final m in _maps(request['aspects'])) {
      final a = YildiznameFactChrome.bodyOf(m['bodyA']);
      final b = YildiznameFactChrome.bodyOf(m['bodyB']);
      final type = m['type'];
      final orb = m['orb'];
      if (a == null || b == null || a == b) continue;
      // Both bodies must themselves be trusted, displayed facts.
      if (!displayedBodies.contains(a) || !displayedBodies.contains(b)) {
        continue;
      }
      if (!YildiznameFactChrome.isAspect(type)) continue;
      if (orb is! num || !orb.isFinite || orb < 0) continue;

      final ra = YildiznameFactChrome.rankOf(a);
      final rb = YildiznameFactChrome.rankOf(b);
      final first = ra <= rb ? a : b;
      final second = ra <= rb ? b : a;
      final key =
          '${YildiznameFactChrome.rankOf(first)}'
          '|${YildiznameFactChrome.rankOf(second)}|$type';
      if (!seen.add(key)) continue;
      rows.add((
        a: YildiznameFactChrome.rankOf(first),
        b: YildiznameFactChrome.rankOf(second),
        type: YildiznameFactChrome.aspectOrder(type as String),
        orb: orb.toDouble(),
        view: YildiznameDisplayAspect(
          first: YildiznameFactChrome.subjectLabel(first, lang),
          second: YildiznameFactChrome.subjectLabel(second, lang),
          type: YildiznameFactChrome.aspectLabel(type, lang),
        ),
      ));
    }
    rows.sort((x, y) {
      final byOrb = x.orb.compareTo(y.orb);
      if (byOrb != 0) return byOrb;
      final byA = x.a.compareTo(y.a);
      if (byA != 0) return byA;
      final byB = x.b.compareTo(y.b);
      if (byB != 0) return byB;
      return x.type.compareTo(y.type);
    });
    return [for (final r in rows.take(maxAspects)) r.view];
  }

  // -- balances (FULL only) ---------------------------------------------------

  static List<YildiznameDisplayBalance> _balances(
    Map<String, dynamic> request,
    String lang,
  ) {
    final raw = _maps(request['balances']);
    YildiznameDisplayBalance? one(
      String kind,
      bool Function(Object?) valid,
      String Function(String) value,
      String title,
    ) {
      final matches = [
        for (final b in raw)
          if (b['kind'] == kind) b,
      ];
      if (matches.length != 1) return null;
      final b = matches.single;
      final dominant = b['dominant'];
      final counts = b['counts'];
      if (!valid(dominant) || counts is! Map) return null;
      final numbers = <String, num>{};
      for (final e in counts.entries) {
        final v = e.value;
        if (e.key is! String || v is! num || !v.isFinite || v < 0) return null;
        numbers[e.key as String] = v;
      }
      final top = numbers[dominant as String];
      if (top == null || top <= 0) return null;
      // The stored dominant must be the UNIQUE maximum. The builder breaks
      // ties silently, and "dominant" over a tie would be a false claim.
      for (final e in numbers.entries) {
        if (e.key != dominant && e.value >= top) return null;
      }
      return YildiznameDisplayBalance(label: title, value: value(dominant));
    }

    final element = one(
      'elements',
      YildiznameFactChrome.isElement,
      (w) => YildiznameFactChrome.elementLabel(w, lang),
      YildiznameFactChrome.balanceElementTitle(lang),
    );
    final quality = one(
      'modalities',
      YildiznameFactChrome.isQuality,
      (w) => YildiznameFactChrome.qualityLabel(w, lang),
      YildiznameFactChrome.balanceQualityTitle(lang),
    );
    return [?element, ?quality];
  }

  // -- helpers ----------------------------------------------------------------

  /// Whole degrees, TRUNCATED (astrological convention): 29.99° reads 29°,
  /// so a value can never round across a sign boundary, and sub-degree
  /// precision the stored value does not warrant is never shown. A genuine
  /// stored `0.0` is a real 0°; only an absent or invalid value returns null.
  static int? _degree(Object? raw) {
    if (raw is! num || !raw.isFinite) return null;
    final v = raw.toDouble();
    if (v < 0 || v >= 30) return null;
    return math.max(0, v.floor());
  }

  static int? _house(Object? raw) {
    if (raw is! num || !raw.isFinite) return null;
    final v = raw.toDouble();
    if (v != v.roundToDouble()) return null;
    final n = v.round();
    return n >= 1 && n <= 12 ? n : null;
  }

  /// A `<prefix>.<body>` factRef that names a DIFFERENT body contradicts the
  /// fact; other reference styles are not judged.
  static bool _refMatches(Object? ref, String prefix, Object? body) {
    if (ref is! String || !ref.startsWith('$prefix.')) return true;
    return ref.substring(prefix.length + 1) == body;
  }

  static List<Map<String, dynamic>> _maps(Object? raw) {
    if (raw is! List) return const [];
    // Entries that are not string-keyed maps are malformed evidence — skipped
    // rather than allowed to throw.
    return [
      for (final e in raw)
        if (e is Map && e.keys.every((k) => k is String))
          Map<String, dynamic>.from(e),
    ];
  }
}
