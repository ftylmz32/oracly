/// Phase 6F — Crossroads stays behind the firewall: not a live Narrative
/// spread and still unreachable from the picker. REAL PROVIDER CALLS = 0.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_gate.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_request_factory.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_spreads.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_crossroads.dart';

import '../narrative_shadow/narrative_shadow_test_support.dart';
import 'phase6f_live_support.dart';

const _crossroadsSource =
    'lib/features/tarot/signature_spreads/signature_spread_crossroads.dart';

ReadingSession _crossroadsSession() => ReadingSession(
      id: 'sess_6f_crossroads',
      deckId: 'classic',
      spread: TarotSpreadType.crossroads,
      intention: const TarotIntention(text: 'A mı B mi?', topic: 'career'),
      shuffleSeed: 1,
      startedAt: DateTime.utc(2026, 9, 24, 12),
      drawnCards: [
        for (var i = 0; i < 5; i++)
          TarotDrawnCard(
            card: ritualCard(i),
            positionIndex: i,
            isReversed: false,
          ),
      ],
    );

void main() {
  tearDown(() => FeatureFlagRuntime.refreshFromRemote(const {}));

  test('Crossroads is absent from the live Narrative spread set', () {
    expect(
      NarrativeTarotLiveSpreads.spreads,
      isNot(contains(TarotSpreadType.crossroads)),
    );
    expect(
      NarrativeTarotLiveSpreads.isLiveLaunchCandidate(
        TarotSpreadType.crossroads,
      ),
      isFalse,
    );
    expect(NarrativeTarotLiveGate.isLaunchSpread(TarotSpreadType.crossroads),
        isFalse);
  });

  test('flag ON still does not route Crossroads to Narrative', () {
    FeatureFlagRuntime.refreshFromRemote({
      ProductFeatureFlags.tarotNarrativeV2.key: true,
    });
    expect(NarrativeTarotLiveGate.isFlagEnabled, isTrue);
    expect(
      NarrativeTarotLiveGate.shouldUseNarrative(TarotSpreadType.crossroads),
      isFalse,
    );
  });

  test('live request factory refuses a Crossroads session', () {
    expect(
      () => NarrativeTarotLiveRequestFactory.build(
        session: _crossroadsSession(),
        languageCode: 'tr',
        historyLoad: emptyHistoryLoad(),
        now: DateTime.utc(2026, 9, 24, 19),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('Crossroads has no Narrative machine spread id', () {
    expect(
      () => NarrativeTarotLiveSpreads.narrativeSpreadId(
        TarotSpreadType.crossroads,
      ),
      throwsArgumentError,
    );
  });

  group('catalog definition', () {
    test('runtime definition is still picker-unreachable', () {
      expect(kSignatureCrossroads.spreadId, 'signature.crossroads');
      expect(kSignatureCrossroads.offeredInLivePicker, isFalse);
    });

    test('source still declares offeredInLivePicker: false', () {
      final source = File(_crossroadsSource).readAsStringSync();
      expect(source, contains('offeredInLivePicker: false'));
      expect(source, isNot(contains('offeredInLivePicker: true')));
    });
  });
}
