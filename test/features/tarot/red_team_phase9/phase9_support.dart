/// Phase 9 — shared corrupt JSON / boot helpers (test-only).
/// REAL PROVIDER CALLS = 0.
library;

import 'dart:convert';

import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../e2e/phase8_failing_repo.dart';
import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import '../narrative_shadow/narrative_shadow_test_support.dart';

Map<String, dynamic> baseThreeJson({String id = 'p9_base'}) =>
    threeContrastSession(id: id).toJson();

String corruptJson(Map<String, dynamic> Function(Map<String, dynamic>) mutate) {
  final m = baseThreeJson();
  return jsonEncode(mutate(Map<String, dynamic>.from(m)));
}

Future<(LocalStorage, Phase8FailingRepo, TarotReadingController)> bootRepo() async {
  SharedPreferences.setMockInitialValues({});
  OraclyL10n.bind('en');
  final storage = LocalStorage(await SharedPreferences.getInstance());
  final repo = Phase8FailingRepo(TarotReadingRepositoryImpl.fromStorage(storage));
  final ctrl = TarotReadingController(repository: repo);
  return (storage, repo, ctrl);
}

/// Scripted AI that waits before returning — race / dispose attacks.
class DelayedScriptedAi extends ScriptedNarrativeAi {
  DelayedScriptedAi(
    super.outcomes, {
    this.delay = const Duration(milliseconds: 80),
  });

  final Duration delay;

  @override
  Future<AiOutcome<Map<String, dynamic>>> generateNarrativeTarotReading({
    required Map<String, dynamic> payload,
    required String fingerprint,
    int attempt = 1,
  }) async {
    await Future<void>.delayed(delay);
    return super.generateNarrativeTarotReading(
      payload: payload,
      fingerprint: fingerprint,
      attempt: attempt,
    );
  }
}

ReadingSession fiveCardSession({String id = 'p9_five'}) => ReadingSession(
      id: id,
      deckId: 'classic',
      spread: TarotSpreadType.fiveCard,
      intention: const TarotIntention(text: '', topic: null),
      shuffleSeed: 1,
      startedAt: DateTime.utc(2026, 9, 25),
      drawnCards: [
        for (var i = 0; i < 5; i++)
          TarotDrawnCard(
            card: ritualCard(i),
            positionIndex: i,
            isReversed: false,
            positionKey: const [
              'situation',
              'hidden_influence',
              'challenge',
              'strength',
              'direction',
            ][i],
          ),
      ],
    );
