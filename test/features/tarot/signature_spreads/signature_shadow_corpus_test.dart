/// Phase 5E — frozen Signature shadow corpus lock.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_bridge.dart';
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

TarotSpreadType _type(String name) =>
    TarotSpreadType.values.firstWhere((t) => t.name == name);

void main() {
  test('frozen signature shadow corpus v1', () {
    final raw = File(
      'test/fixtures/tarot_signature_shadow_v1.json',
    ).readAsStringSync();
    final root = jsonDecode(raw) as Map<String, dynamic>;
    final scenarios = root['scenarios'] as List<dynamic>;

    expect(root['version'], 1);
    expect(root['phase'], '6G');
    expect(root['scenarioCount'], scenarios.length);
    expect(root['launchSpreadCount'], 4);
    expect(root['crossroadsPhase3Support'], isTrue);
    expect(root['crossroadsPhase4HistorySupport'], isTrue);
    expect(root['liveNarrativeV2'], isFalse);
    expect(scenarios, hasLength(16));

    for (var i = 0; i < scenarios.length; i++) {
      final row = Map<String, dynamic>.from(scenarios[i] as Map);
      final drawn = (row['drawn'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final result = SignatureSpreadShadowEvaluator.evaluate(
        input: SignatureSpreadShadowInput(
          sessionId: 'sess_${row['scenarioId']}',
          readingId: 'read_${row['scenarioId']}',
          languageCode: row['languageCode'] as String,
          spreadType: _type(row['runtimeEnum'] as String),
          questionRaw: row['question'] as String?,
          intentionTopic: row['topic'] as String?,
          cards: [
            for (var p = 0; p < drawn.length; p++)
              SignatureSpreadShadowCard(
                ritualCardId: _ritual(drawn[p]['id'] as String),
                isReversed: drawn[p]['reversed'] as bool,
                positionIndex: p,
              ),
          ],
        ),
      );
      final actual = serializeShadowResult(result);
      final expected = Map<String, dynamic>.from(row['expected'] as Map);
      expect(
        actual,
        expected,
        reason: 'scenario ${row['scenarioId']} index=$i drifted',
      );
    }

    final df = scenarios.cast<Map>().firstWhere(
      (s) => s['scenarioId'] == 'df_open_en',
    );
    final cr = scenarios.cast<Map>().firstWhere(
      (s) => s['scenarioId'] == 'cr_decision_en',
    );
    expect(df['distinctnessPair'], 'same_five_v1');
    expect(cr['distinctnessPair'], 'same_five_v1');
    expect(df['drawn'], cr['drawn']);
    final dfFp =
        (df['expected'] as Map)['structuralFingerprint'] as String;
    final crFp =
        (cr['expected'] as Map)['structuralFingerprint'] as String;
    expect(dfFp, isNot(crFp));
  });
}
