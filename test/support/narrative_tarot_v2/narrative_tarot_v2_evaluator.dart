/// Phase 2 offline CONTRACT HARNESS evaluator.
///
/// NOT production NarrativeQualityValidator. Offline only. No providers.
/// Later production validators must be tested against the same corpus.
library;

import 'narrative_tarot_v2_hard_scan.dart';
import 'narrative_tarot_v2_models.dart';
import 'narrative_tarot_v2_soft_flags.dart';
import 'narrative_tarot_v2_text.dart';

class Ntv2Evaluation {
  Ntv2Evaluation({required this.hardFailures, required this.flags});

  final Set<String> hardFailures;
  final Map<String, bool> flags;
}

abstract final class Ntv2ContractEvaluator {
  static Ntv2Evaluation evaluate(Ntv2Scenario s) {
    final hard = <String>{};
    final input = s.input;
    final candidate = s.candidate;
    final cards = (input['cards'] as List).cast<Map>();
    final drawn = cards.map((c) => c['canonicalCardId'] as String).toSet();
    final positions = cards.map((c) => c['positionKey'] as String).toSet();
    final positionByCard = {
      for (final c in cards)
        c['canonicalCardId'] as String: c['positionKey'] as String,
    };
    final orientation = {
      for (final c in cards)
        c['canonicalCardId'] as String: c['isReversed'] as bool,
    };
    final relIds = {
      for (final r in (input['relationships'] as List? ?? const []))
        (r as Map)['evidenceId'] as String,
    };
    final mem = Map<String, dynamic>.from(input['memory'] as Map? ?? {});
    final memEntries = (mem['entries'] as List? ?? const []).cast<Map>();
    final memRefs = {for (final e in memEntries) e['evidenceRef'] as String};
    final foreignRefs = {
      for (final e in memEntries)
        if ('${e['contentForModel']}'.contains('FOREIGN_ACCOUNT'))
          e['evidenceRef'] as String,
    };
    final deletedRefs = {
      for (final e in memEntries)
        if ('${e['contentForModel']}'.contains('DELETED_SOURCE'))
          e['evidenceRef'] as String,
    };
    final recurringCards = (input['recurringCards'] as List? ?? const [])
        .cast<Map>();
    final recurringThemes = (input['recurringThemes'] as List? ?? const [])
        .cast<Map>();
    final recIds = <String>{
      for (final r in recurringCards) r['evidenceId'] as String,
      for (final r in recurringThemes) r['evidenceId'] as String,
    };
    final recCounts = {
      for (final r in recurringCards)
        r['canonicalCardId'] as String: r['occurrenceCount'] as int,
    };
    final recentNames = ((mem['recentCardNames'] as List?) ?? const [])
        .cast<String>();
    final beats = (candidate['beats'] as List? ?? const []).cast<Map>();
    final details = (candidate['cardDetails'] as List? ?? const []).cast<Map>();
    final text = Ntv2TextHeuristics.allText(candidate, beats);

    Ntv2HardScan.scanBeatRefs(
      beats,
      positionByCard: positionByCard,
      drawn: drawn,
      positions: positions,
      relIds: relIds,
      memRefs: memRefs,
      recIds: recIds,
      hard: hard,
    );
    Ntv2HardScan.scanCardDetails(
      details,
      positionByCard: positionByCard,
      orientation: orientation,
      drawn: drawn,
      positions: positions,
      hard: hard,
    );
    Ntv2HardScan.checkRecurrence(text, recCounts, recIds, hard);
    Ntv2HardScan.checkCertaintySafety(text, hard);
    Ntv2HardScan.checkMemoryPrivacy(beats, foreignRefs, deletedRefs, hard);
    Ntv2HardScan.checkLanguage(s.locale, text, hard);

    final flags = Ntv2SoftFlags.compute(
      s: s,
      text: text,
      hard: hard,
      drawn: drawn,
      beats: beats,
      details: details,
      relIds: relIds,
      memRefs: memRefs,
      foreignRefs: foreignRefs,
      recIds: recIds,
      mem: mem,
      recentNames: recentNames,
      recCounts: recCounts,
    );

    return Ntv2Evaluation(hardFailures: hard, flags: flags);
  }
}
