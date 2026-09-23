/// One-shot corpus dump — run then freeze output into fixtures.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_bridge.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_evaluator.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_input.dart';

import 'signature_shadow_serialize.dart';

int _ritual(String canonical) {
  for (var i = 0; i < 78; i++) {
    if (OraclyTarotBridge.byRitualId(i)?.id == canonical) return i;
  }
  throw StateError(canonical);
}

List<SignatureSpreadShadowCard> _cards(
  TarotSpreadType type,
  List<(String id, bool rev)> drawn,
) {
  return [
    for (var i = 0; i < drawn.length; i++)
      SignatureSpreadShadowCard(
        ritualCardId: _ritual(drawn[i].$1),
        isReversed: drawn[i].$2,
        positionIndex: i,
      ),
  ];
}

Map<String, dynamic> _run({
  required String id,
  required TarotSpreadType type,
  required String lang,
  required List<(String, bool)> drawn,
  String? question,
  String? topic,
  String? distinctnessPair,
}) {
  final result = SignatureSpreadShadowEvaluator.evaluate(
    input: SignatureSpreadShadowInput(
      sessionId: 'sess_$id',
      readingId: 'read_$id',
      languageCode: lang,
      spreadType: type,
      questionRaw: question,
      intentionTopic: topic,
      cards: _cards(type, drawn),
    ),
  );
  final facts = serializeShadowResult(result);
  return {
    'scenarioId': id,
    if (distinctnessPair != null) 'distinctnessPair': distinctnessPair,
    'runtimeEnum': type.name,
    'languageCode': lang,
    'question': question,
    'topic': topic,
    'drawn': [
      for (final d in drawn) {'id': d.$1, 'reversed': d.$2},
    ],
    'expected': facts,
  };
}

void main() {
  test('dump shadow corpus v1', () {
    final five = OraclyTarotDeck.expectedIds.take(5).toList();
    final fiveDrawn = <(String, bool)>[
      (five[0], false),
      (five[1], true),
      (five[2], false),
      (five[3], true),
      (five[4], false),
    ];
    final scenarios = <Map<String, dynamic>>[
      _run(
        id: 'qi_open_en_up',
        type: TarotSpreadType.single,
        lang: 'en',
        drawn: [(five[0], false)],
        question: null,
      ),
      _run(
        id: 'qi_guidance_tr_rev',
        type: TarotSpreadType.single,
        lang: 'tr',
        drawn: [(five[0], true)],
        question: 'Need guidance for my next step',
      ),
      _run(
        id: 'qi_decision_reject',
        type: TarotSpreadType.single,
        lang: 'en',
        drawn: [(five[0], false)],
        question: 'Should I accept this offer?',
      ),
      _run(
        id: 'tl_open_en',
        type: TarotSpreadType.threeCard,
        lang: 'en',
        drawn: [(five[0], false), (five[1], false), (five[2], false)],
      ),
      _run(
        id: 'tl_relationship_tr',
        type: TarotSpreadType.threeCard,
        lang: 'tr',
        drawn: [(five[0], false), (five[1], true), (five[2], false)],
        question: 'How is this relationship evolving?',
      ),
      _run(
        id: 'tl_decision_ru',
        type: TarotSpreadType.threeCard,
        lang: 'ru',
        drawn: [(five[0], true), (five[1], false), (five[2], true)],
        question: 'Should I accept this offer?',
      ),
      _run(
        id: 'df_open_en',
        type: TarotSpreadType.fiveCard,
        lang: 'en',
        drawn: fiveDrawn,
        distinctnessPair: 'same_five_v1',
      ),
      _run(
        id: 'df_guidance_tr_rev',
        type: TarotSpreadType.fiveCard,
        lang: 'tr',
        drawn: [
          (five[0], true),
          (five[1], true),
          (five[2], false),
          (five[3], true),
          (five[4], false),
        ],
        question: 'Need guidance for my next step',
      ),
      _run(
        id: 'df_relationship_ru',
        type: TarotSpreadType.fiveCard,
        lang: 'ru',
        drawn: [
          (five[0], false),
          (five[1], false),
          (five[2], true),
          (five[3], false),
          (five[4], true),
        ],
        question: 'How is this relationship evolving?',
      ),
      _run(
        id: 'df_decision_en',
        type: TarotSpreadType.fiveCard,
        lang: 'en',
        drawn: [
          (five[0], false),
          (five[1], true),
          (five[2], true),
          (five[3], false),
          (five[4], false),
        ],
        question: 'Should I accept this offer?',
      ),
      _run(
        id: 'cr_decision_en',
        type: TarotSpreadType.crossroads,
        lang: 'en',
        drawn: fiveDrawn,
        question: 'Should I accept this offer?',
        distinctnessPair: 'same_five_v1',
      ),
      _run(
        id: 'cr_decision_tr_mixed',
        type: TarotSpreadType.crossroads,
        lang: 'tr',
        drawn: [
          (five[0], true),
          (five[1], false),
          (five[2], true),
          (five[3], false),
          (five[4], true),
        ],
        question: 'Should I accept this offer?',
      ),
      _run(
        id: 'cr_guidance_ru',
        type: TarotSpreadType.crossroads,
        lang: 'ru',
        drawn: fiveDrawn,
        question: 'Need guidance for my next step',
      ),
      _run(
        id: 'cr_open_en',
        type: TarotSpreadType.crossroads,
        lang: 'en',
        drawn: fiveDrawn,
      ),
      _run(
        id: 'cr_relationship_reject',
        type: TarotSpreadType.crossroads,
        lang: 'en',
        drawn: fiveDrawn,
        question: 'How is this relationship evolving?',
      ),
      // 16th: Quick Insight relationship reject (extra reject class)
      _run(
        id: 'qi_relationship_reject',
        type: TarotSpreadType.single,
        lang: 'en',
        drawn: [(five[0], false)],
        question: 'How is this relationship evolving?',
      ),
    ];

    final root = {
      'version': 1,
      'phase': '5E',
      'scenarioCount': scenarios.length,
      'launchSpreadCount': 4,
      'crossroadsPhase3Support': false,
      'crossroadsPhase4HistorySupport': false,
      'liveNarrativeV2': false,
      'note':
          'Literal frozen Signature shadow corpus. Do not regenerate in tests.',
      'scenarios': scenarios,
    };
    // ignore: avoid_print
    print(const JsonEncoder.withIndent('  ').convert(root));
    expect(scenarios, hasLength(16));
  }, skip: 'dump only — enable locally to refresh fixture');
}
