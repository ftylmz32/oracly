/// CALIBRATION ONLY — NOT PRODUCTION SCORER.
///
/// Phase 3D.1B.1 diagnostic: exhaustively measures raw vs normalized
/// overlap scale over C(156,2)=12090 orientation pairs.
library;

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/domain/reversed_transform_kind.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_keyword_discrimination.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_position_edges.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_semantic_channel.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_transform_signals.dart';

class _Ori {
  _Ori(
    this.cardId,
    this.reversed,
    this.channel,
    this.keywordIds,
    this.transforms,
  );
  final String cardId;
  final bool reversed;
  final NarrativeSemanticChannel channel;
  final List<String> keywordIds;
  final List<ReversedTransformKind> transforms;
}

double _pct(List<double> xs, double p) {
  final s = [...xs]..sort();
  final i = ((s.length - 1) * p).round().clamp(0, s.length - 1);
  return s[i];
}

Map<String, Object> _dist(List<double> xs) {
  if (xs.isEmpty) return const {'count': 0};
  final s = [...xs]..sort();
  int ge(double t) => s.where((v) => v >= t).length;
  return {
    'count': s.length,
    'min': double.parse(s.first.toStringAsFixed(6)),
    'p25': double.parse(_pct(s, 0.25).toStringAsFixed(6)),
    'median': double.parse(_pct(s, 0.5).toStringAsFixed(6)),
    'p75': double.parse(_pct(s, 0.75).toStringAsFixed(6)),
    'p90': double.parse(_pct(s, 0.9).toStringAsFixed(6)),
    'p95': double.parse(_pct(s, 0.95).toStringAsFixed(6)),
    'max': double.parse(s.last.toStringAsFixed(6)),
    'ge1_pct': double.parse((100 * ge(1.0) / s.length).toStringAsFixed(2)),
    'ge1_25_pct': double.parse((100 * ge(1.25) / s.length).toStringAsFixed(2)),
    'ge2_pct': double.parse((100 * ge(2.0) / s.length).toStringAsFixed(2)),
    'ge3_pct': double.parse((100 * ge(3.0) / s.length).toStringAsFixed(2)),
    'ge3_5_pct': double.parse((100 * ge(3.5) / s.length).toStringAsFixed(2)),
  };
}

void main() {
  test('3D.1B.1 calibration locks — RAW SATURATION + NORMALIZED B', () {
    expect(NarrativeTarotProfileCatalog.all, hasLength(78));
    expect(NarrativeKeywordIds.all, hasLength(128));
    expect(NarrativeKeywordDiscrimination.documentFrequency, hasLength(128));
    expect(NarrativeKeywordDiscrimination.df(NarrativeKeywordIds.scatter), 14);
    expect(NarrativeKeywordDiscrimination.df(NarrativeKeywordIds.haste), 13);

    final allW = <double>[];
    final usedW = <double>[];
    final usedByWeight = <MapEntry<String, int>>[];
    for (final e in NarrativeKeywordDiscrimination.documentFrequency.entries) {
      final w = NarrativeKeywordDiscrimination.weight(e.key);
      allW.add(w);
      if (e.value > 0) {
        usedW.add(w);
        usedByWeight.add(e);
      }
    }
    allW.sort();
    usedW.sort();
    expect(allW.last, 6.0);
    expect(usedW.first, closeTo(3.348195604246098, 1e-9));

    usedByWeight.sort((a, b) {
      final wa = NarrativeKeywordDiscrimination.weight(a.key);
      final wb = NarrativeKeywordDiscrimination.weight(b.key);
      return wb.compareTo(wa);
    });
    final topDisc = usedByWeight.take(10).map((e) => e.key).toList();
    usedByWeight.sort((a, b) => b.value.compareTo(a.value));
    final lowDisc = usedByWeight
        .take(10)
        .map((e) => '${e.key}:${e.value}')
        .toList();

    final oris = <_Ori>[];
    var kwTagOverlapOris = 0;
    final tagOnlyOriFreq = <String, int>{};
    for (final p in NarrativeTarotProfileCatalog.all) {
      for (final rev in [false, true]) {
        final ori = rev ? p.reversed : p.upright;
        final ch = NarrativeSemanticChannel.from(
          keywordIds: ori.keywordIds,
          symbolTags: p.symbolTags,
        );
        if (ch.keywordTagDuplicateIds.isNotEmpty) kwTagOverlapOris++;
        for (final t in ch.tagOnlyIds) {
          tagOnlyOriFreq[t] = (tagOnlyOriFreq[t] ?? 0) + 1;
        }
        oris.add(
          _Ori(
            p.canonicalCardId,
            rev,
            ch,
            List.of(ori.keywordIds),
            List.of(ori.transforms),
          ),
        );
      }
    }
    expect(oris, hasLength(156));
    expect(kwTagOverlapOris, 64);
    expect(oris.length * (oris.length - 1) ~/ 2, 12090);

    final rawAll = <double>[];
    final normAll = <double>[];
    final satAll = <double>[];
    final raw1 = <double>[], raw2 = <double>[], raw3 = <double>[];
    final rawHf = <double>[], rawSpec = <double>[];
    final norm1 = <double>[], norm2 = <double>[], norm3 = <double>[];
    final normHf = <double>[], normSpec = <double>[];
    final tagOnlyPairCounts = <String, int>{};
    var pairsWithOverlap = 0;

    for (var i = 0; i < oris.length; i++) {
      for (var j = i + 1; j < oris.length; j++) {
        final a = oris[i];
        final b = oris[j];
        final shared = a.channel.semanticIds.toSet().intersection(
          b.channel.semanticIds.toSet(),
        );
        final tagShared = a.channel.tagOnlyIds.toSet().intersection(
          b.channel.tagOnlyIds.toSet(),
        );
        for (final t in tagShared) {
          tagOnlyPairCounts[t] = (tagOnlyPairCounts[t] ?? 0) + 1;
        }
        if (shared.isEmpty) continue;
        pairsWithOverlap++;
        var raw = 0.0;
        var norm = 0.0;
        var allHf = true;
        var allSpecific = true;
        for (final id in shared) {
          final w = NarrativeKeywordDiscrimination.weight(id);
          raw += w;
          norm += w / 6.0;
          final df = NarrativeKeywordDiscrimination.df(id);
          if (df < 8) allHf = false;
          if (df >= 8) allSpecific = false;
        }
        rawAll.add(raw);
        normAll.add(norm);
        satAll.add(1 - math.exp(-norm));
        if (shared.length == 1) {
          raw1.add(raw);
          norm1.add(norm);
        } else if (shared.length == 2) {
          raw2.add(raw);
          norm2.add(norm);
        } else {
          raw3.add(raw);
          norm3.add(norm);
        }
        if (allHf) {
          rawHf.add(raw);
          normHf.add(norm);
        }
        if (allSpecific) {
          rawSpec.add(raw);
          normSpec.add(norm);
        }
      }
    }

    // RAW saturation: single-id min already >3.0; many pairs ≥3.5.
    expect(raw1.first, greaterThan(3.0));
    expect(_pct(rawAll, 0.5), greaterThan(3.0));
    expect(
      rawAll.where((v) => v >= 3.5).length / rawAll.length,
      greaterThan(0.4),
    );

    // NORMALIZED B: single id in ~[0.558, 1.0]; median far below 3.5.
    expect(_pct(norm1, 0.0), greaterThanOrEqualTo(0.55));
    expect(_pct(norm1, 1.0), lessThanOrEqualTo(1.0));
    expect(_pct(normAll, 0.5), lessThan(1.5));
    expect(_pct(normAll, 0.95), lessThan(3.0));
    // Theme echo threshold 2.0: single id cannot; multi-id can.
    expect(_pct(norm1, 1.0), lessThan(2.0));

    // FR-F01/F02: keywordIds identical; semantic channels differ via tags.
    final w11 = NarrativeTarotProfileCatalog.lookup('wands_11')!;
    final p11 = NarrativeTarotProfileCatalog.lookup('pentacles_11')!;
    expect(w11.upright.keywordIds.toSet(), p11.upright.keywordIds.toSet());
    final s11 = NarrativeTarotProfileCatalog.lookup('swords_11')!;
    final s12 = NarrativeTarotProfileCatalog.lookup('swords_12')!;
    expect(s11.reversed.keywordIds.toSet(), s12.reversed.keywordIds.toSet());

    double normSharedKeywords(List<String> a, List<String> b) {
      final shared = a.toSet().intersection(b.toSet());
      var n = 0.0;
      for (final id in shared) {
        n += NarrativeKeywordDiscrimination.weight(id) / 6.0;
      }
      return n;
    }

    final f01KwNorm = normSharedKeywords(
      w11.upright.keywordIds,
      p11.upright.keywordIds,
    );
    final f01Capped = math.min(f01KwNorm, 0.35);
    expect(f01Capped, 0.35);
    // Identity-only: capped overlap alone rejects all admission paths.
    expect(f01Capped, lessThan(1.0));
    expect(f01Capped, lessThan(1.25));
    // FR-F01 + canonical only: 0.90 < canonical threshold 1.0 → REJECT.
    final f01PlusCanonical = f01Capped + 0.55;
    expect(f01PlusCanonical, closeTo(0.90, 1e-12));
    expect(f01PlusCanonical < 1.0, isTrue);
    // SYNTHETIC guarded admit: + opposition 0.40 → S=1.30, strength ≤ 0.45.
    final f01Guarded = f01PlusCanonical + 0.40;
    expect(f01Guarded, closeTo(1.30, 1e-12));
    expect(f01Guarded >= 1.0, isTrue);
    expect(f01Guarded / 3.5, lessThanOrEqualTo(0.45));

    final f02KwNorm = normSharedKeywords(
      s11.reversed.keywordIds,
      s12.reversed.keywordIds,
    );
    final f02Capped = math.min(f02KwNorm, 0.35);
    expect(f02Capped, 0.35);
    // FR-F02 + supportive only: 0.65 < position-strong 1.0 → REJECT.
    final f02PlusSupportive = f02Capped + 0.30;
    expect(f02PlusSupportive, closeTo(0.65, 1e-12));
    expect(f02PlusSupportive < 1.0, isTrue);
    // SYNTHETIC guarded admit: + canonical + opposition.
    final f02Guarded = f02Capped + 0.55 + 0.40;
    expect(f02Guarded, closeTo(1.30, 1e-12));
    expect(f02Guarded >= 1.0, isTrue);
    expect(f02Guarded / 3.5, lessThanOrEqualTo(0.45));

    // Canonical inventory.
    var storedRefs = 0;
    final undirected = <String>{};
    final directed = <String>{};
    var invalid = 0;
    var self = 0;
    final expected = OraclyTarotDeck.expectedIds.toSet();
    for (final c in OraclyTarotDeck.all) {
      for (final r in c.relationshipWithOtherCards.relatedIds) {
        storedRefs++;
        if (r == c.id) {
          self++;
          continue;
        }
        if (!expected.contains(r)) {
          invalid++;
          continue;
        }
        directed.add('${c.id}>$r');
        final lo = c.id.compareTo(r) <= 0 ? c.id : r;
        final hi = c.id.compareTo(r) <= 0 ? r : c.id;
        undirected.add('$lo|$hi');
      }
    }
    var mutual = 0;
    var oneWay = 0;
    for (final pair in undirected) {
      final parts = pair.split('|');
      final ab = '${parts[0]}>${parts[1]}';
      final ba = '${parts[1]}>${parts[0]}';
      if (directed.contains(ab) && directed.contains(ba)) {
        mutual++;
      } else {
        oneWay++;
      }
    }
    expect(invalid, 0);
    expect(self, 0);

    final edgeKinds = <String, int>{};
    for (final e in kAuthoritativePositionEdges) {
      edgeKinds[e.edgeKind.name] = (edgeKinds[e.edgeKind.name] ?? 0) + 1;
    }
    expect(kAuthoritativePositionEdges, hasLength(29));
    expect(tagOnlyOriFreq.isNotEmpty, isTrue);
    expect(NarrativeTransformPairSignals.exactNameKeywordIntersection, [
      'avoidance',
      'delay',
      'misdirection',
      'release',
    ]);

    // Snapshot for calibration document.
    // ignore: avoid_print
    print({
      'pairsWithOverlap': pairsWithOverlap,
      'raw': _dist(rawAll),
      'raw1': _dist(raw1),
      'raw2': _dist(raw2),
      'raw3': _dist(raw3),
      'rawHf': _dist(rawHf),
      'rawSpec': _dist(rawSpec),
      'norm': _dist(normAll),
      'norm1': _dist(norm1),
      'norm2': _dist(norm2),
      'norm3': _dist(norm3),
      'normHf': _dist(normHf),
      'normSpec': _dist(normSpec),
      'sat': _dist(satAll),
      'usedWeightMin': usedW.first,
      'usedWeightMax': usedW.last,
      'allWeightMax': allW.last,
      'usedWeightMean': usedW.reduce((a, b) => a + b) / usedW.length,
      'usedWeightMedian': _pct(usedW, 0.5),
      'topDisc': topDisc,
      'lowDisc': lowDisc,
      'canonical': {
        'storedRefs': storedRefs,
        'uniquePairs': undirected.length,
        'mutual': mutual,
        'oneWay': oneWay,
      },
      'edges': edgeKinds,
      'f01KwNorm': f01KwNorm,
      'f02KwNorm': f02KwNorm,
      'tagOnlyIds': (tagOnlyOriFreq.keys.toList()..sort()),
      'tagOnlyOriFreq': tagOnlyOriFreq,
      'tagOnlyPairTop':
          (tagOnlyPairCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(12)
              .map((e) => '${e.key}:${e.value}')
              .toList(),
    });
  });
}
