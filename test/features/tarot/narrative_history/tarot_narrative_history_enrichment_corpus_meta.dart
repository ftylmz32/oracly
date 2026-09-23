/// Meta coverage assertions for Phase 4D enrichment corpus.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_memory_evidence.dart';

import '../narrative_evidence/narrative_evidence_test_support.dart';

const requiredClasses = [
  'no_history',
  'privacy_blocked_rich',
  'one_prior_same_card',
  'same_card_multi_prior',
  'same_card_gt5',
  'same_card_outside_90d',
  'future_tarot_row',
  'current_readingId_exclusion',
  'current_sessionId_exclusion',
  'physical_duplicate_dedupe',
  'missing_positionKey_count_no_sample',
  'unknown_legacy_orientation',
  'context_topic_match',
  'context_kind_token',
  'context_keyword_map',
  'same_card_alone_context_false',
  'same_spread_alone_context_false',
  'generic_topic_context_false',
  'gt20_prior_scan_cap',
  'two_tarot_same_theme_no_historical_theme',
  'tarot_coffee_same_theme',
  'coffee_dream_same_theme',
  'same_raw_source_id_two_types',
  'irrelevant_cross_feature_theme',
  'gt4_qualifying_themes',
  'current_spread_theme_echo_no_history',
  'memory_theme_relevance',
  'memory_two_token_relevance',
  'memory_one_token_reject',
  'memory_card_map_relevance',
  'explicit_recall_tr',
  'explicit_recall_en',
  'explicit_recall_ru',
  'memory_gt220_entry',
  'memory_gt800_aggregate',
  'memory_max_4_entries',
  'omit_no_history',
  'omit_empty',
  'omit_irrelevant',
  'omit_included',
  'same_timestamp_tie',
  'input_reorder_determinism',
  're_enrichment_idempotence',
  'privacy_revocation',
];

void assertEnrichmentCorpusMeta(List<Map<String, dynamic>> scenarios) {
  expect(scenarios.length, greaterThanOrEqualTo(36));

  final tagged = <String>{};
  final langs = <String, int>{};
  final kinds = <String, int>{};
  var privacy = 0;
  var withRecCard = 0;
  var with2RecCards = 0;
  var ctxFalse = 0;
  var ctxTrue = 0;
  var withTheme = 0;
  var withMemory = 0;
  var omitIrrelevant = 0;
  final epistemics = <String>{};
  final themeLabels = <String>{};

  for (final s in scenarios) {
    for (final c in (s['classes'] as List).cast<String>()) {
      tagged.add(c);
    }
    if (s['privacyBlocked'] == true) privacy++;
    final phase3 = loadEvidenceCorpus();
    final baseId = s['baseScenarioId'] as String;
    final p3 = (phase3['scenarios'] as List).cast<Map>().firstWhere(
      (x) => x['id'] == baseId,
    );
    final lang = (p3['input'] as Map)['languageCode'] as String;
    langs[lang] = (langs[lang] ?? 0) + 1;
    final kind = ((p3['expected'] as Map)['question'] as Map)['kind'] as String;
    kinds[kind] = (kinds[kind] ?? 0) + 1;

    final exp = s['expected'] as Map<String, dynamic>;
    final cards = (exp['recurringCards'] as List?) ?? const [];
    if (cards.isNotEmpty) withRecCard++;
    if (cards.length >= 2) with2RecCards++;
    final hasCtxTrue = cards.any((c) => (c as Map)['contextsOverlap'] == true);
    final hasCtxFalse =
        cards.isNotEmpty &&
        cards.any((c) => (c as Map)['contextsOverlap'] == false);
    if (hasCtxTrue) ctxTrue++;
    if (hasCtxFalse) ctxFalse++;
    final themes = (exp['recurringThemes'] as List?) ?? const [];
    if (themes.isNotEmpty) withTheme++;
    for (final t in themes) {
      themeLabels.add((t as Map)['themeIdOrLabel'] as String);
    }
    final mem = exp['memory'] as Map;
    if (mem['included'] == true) withMemory++;
    final reason = mem['omitReason'] as String?;
    if (reason == 'irrelevant' || reason == 'empty' || reason == 'no_history') {
      omitIrrelevant++;
    }
    for (final e in (mem['entries'] as List?) ?? const []) {
      epistemics.add((e as Map)['epistemic'] as String? ?? 'interpretation');
    }
    for (final r
        in (s['history'] as Map)['tarotReadings'] as List? ?? const []) {
      for (final c in (r as Map)['cards'] as List? ?? const []) {
        expect(
          OraclyTarotDeck.byId((c as Map)['canonicalCardId'] as String),
          isNotNull,
        );
      }
    }
    final blob = jsonEncode(exp);
    expect(blob.contains('owner_a'), isFalse);
    expect(blob.contains('owner_b'), isFalse);
  }

  for (final c in requiredClasses) {
    expect(tagged.contains(c), isTrue, reason: 'missing class $c');
  }
  for (final lang in ['tr', 'en', 'ru']) {
    expect(langs[lang] ?? 0, greaterThanOrEqualTo(6));
  }
  for (final kind in ['open', 'guidance', 'relationship', 'decision']) {
    expect(kinds[kind] ?? 0, greaterThanOrEqualTo(6));
  }
  expect(privacy, greaterThanOrEqualTo(3));
  expect(withRecCard, greaterThanOrEqualTo(10));
  expect(with2RecCards, greaterThanOrEqualTo(5));
  expect(ctxFalse, greaterThanOrEqualTo(5));
  expect(ctxTrue, greaterThanOrEqualTo(5));
  expect(withTheme, greaterThanOrEqualTo(8));
  expect(themeLabels.contains('ilişki'), isTrue);
  expect(themeLabels.contains('karar'), isTrue);
  final extra = [
    'değişim',
    'sınır',
    'kariyer',
    'iletişim',
    'belirsizlik',
    'özgüven',
  ];
  expect(extra.where(themeLabels.contains).length, greaterThanOrEqualTo(2));
  expect(withMemory, greaterThanOrEqualTo(10));
  expect(omitIrrelevant, greaterThanOrEqualTo(5));
  for (final e in MemoryEvidenceEpistemic.values) {
    expect(epistemics.contains(e.name), isTrue);
  }
}
