/// WAVE 1.5 — the server settled (debited) a Tarot reading but the success
/// response never reached the client. Retrying the SAME reading must reach
/// the server's idempotent settle (same operation id → replay, no second
/// debit) and complete, even though the wallet now shows 0 gems.
/// A new / different reading with too few gems must still be refused.
///
/// Production-faithful wiring: real TarotReadingCharge →
/// PaidAiOperationCoordinator → GemWalletService → GemWalletGateway, against
/// FakeGemAuthority (mirrors backend: replay checked before balance).
/// REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/data/paid_ai_operation_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/models/paid_ai_operation.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_gateway.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_id.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_completion.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_interpreter.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';
import 'package:oracly_new/features/tarot/services/tarot_reading_load_path.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_gem_authority.dart';
import '../narrative_history/tarot_4c_test_support.dart';
import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';

/// Transport in front of the server: the server fully processes every
/// request; only the client-side delivery of one settle response can be lost.
class _LossyTransport {
  _LossyTransport(this.server);

  final FakeGemAuthority server;
  bool loseNextSettleResponse = false;
  bool dropNextSettleRequest = false;
  final Map<String, int> settlePosts = <String, int>{};
  int debits = 0;

  Future<ReadingOperationWire?> send(
    String method,
    String path,
    Map<String, Object>? body,
  ) async {
    final isSettle =
        path.startsWith('/v1/gems/tarot/') && path.endsWith('/settle');
    if (isSettle && dropNextSettleRequest) {
      dropNextSettleRequest = false;
      return null; // never reached the server: no debit happened
    }
    final wire = await server.send(method, path, body);
    if (!isSettle) return wire;
    final op = path.split('/')[4];
    settlePosts[op] = (settlePosts[op] ?? 0) + 1;
    final data = wire?.json?['data'];
    if (wire?.statusCode == 200 && data is Map && data['idempotent'] == false) {
      debits += 1;
    }
    if (loseNextSettleResponse) {
      loseNextSettleResponse = false;
      return null; // server debited; the response never arrived
    }
    return wire;
  }

  int postsFor(String sessionId) =>
      settlePosts[PaidAiOperationId.fromExisting('tarot', sessionId)] ?? 0;
}

class _World {
  _World._(this.storage, this.server, this.transport, this.wallet, this.charge);

  final LocalStorage storage;
  final FakeGemAuthority server;
  final _LossyTransport transport;
  final GemWalletService wallet;
  final TarotReadingCharge charge;
  late final Phase4cHarness harness = Phase4cHarness(storage);

  static Future<_World> create({required int gems}) async {
    SharedPreferences.setMockInitialValues({});
    OraclyL10n.bind('en');
    final storage = LocalStorage(await SharedPreferences.getInstance());
    return onStorage(storage, gems: gems);
  }

  /// A second account/device: own server balance, same local storage.
  static Future<_World> onStorage(
    LocalStorage storage, {
    required int gems,
  }) async {
    final server = FakeGemAuthority(balance: gems);
    final transport = _LossyTransport(server);
    final wallet = GemWalletService(
      GemWalletStore(storage),
      gateway: GemWalletGateway(transport.send),
    );
    await wallet.refresh();
    return _World._(
      storage,
      server,
      transport,
      wallet,
      TarotReadingCharge(wallet, storage),
    );
  }

  TarotInterpretationService interpretation(ScriptedNarrativeAi ai) =>
      TarotInterpretationService(
        narrativeInterpreter: NarrativeTarotLiveInterpreter(
          ai: ai,
          historyLoader: harness.loader(),
          cache: CountingInterpretationCache(),
          clock: () => DateTime.utc(2026, 10, 4, 20),
        ),
        allowLocalFallback: false,
      );

  /// Production load path (same entry the reading screen uses).
  Future<AiReadingContent?> open(
    ReadingSession session,
    TarotInterpretationService interp,
  ) =>
      TarotReadingLoadPath.resolve(
        session: session,
        charge: charge,
        completion: TarotReadingCompletion(
          charge: charge,
          interpretation: interp,
        ),
        generate: () => interp.generateContent(session, language: 'en'),
        shouldCommit: () => true,
      );
}

ScriptedNarrativeAi _ai([int replies = 3]) => ScriptedNarrativeAi([
      for (var i = 0; i < replies; i++)
        AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);

/// Exactly one paid reading's worth of gems.
int get _cost => GemEconomy.tarotReading;

/// First attempt: provider OK, server debits, settle response lost.
Future<ReadingSession> _paidButResponseLost(_World w) async {
  final session = threeContrastSession(id: 'wave15_lost_settle');
  w.transport.loseNextSettleResponse = true;
  final first = await w.open(session, w.interpretation(_ai()));

  // Scenario facts (not the defect): server charged, client did not learn it.
  expect(first, isNull, reason: 'client never received the settle success');
  expect(w.transport.debits, 1);
  expect(w.server.balance, 0);
  expect(w.transport.postsFor(session.id), 1);
  expect(w.charge.alreadyCharged(session.id), isFalse);
  expect(w.wallet.balance, 0, reason: 'wallet re-hydrated from the server');
  return session;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('precondition: paid spread costs exactly the seeded balance', () {
    expect(_cost, greaterThan(0));
    expect(_cost, 20, reason: 'FakeGemAuthority debits 20 per settle');
  });

  test('LOST SETTLE RESPONSE — same reading retry reaches idempotent server '
      'settle and completes without a second debit', () async {
    final w = await _World.create(gems: _cost);
    final session = await _paidButResponseLost(w);

    final retry = await w.open(session, w.interpretation(_ai()));

    expect(w.transport.postsFor(session.id), 2,
        reason: 'the SAME operation id must reach the server again; a local '
            'canAfford(0 gems) check must not block a paid reading');
    expect(retry, isNotNull, reason: 'paid reading must be delivered');
    expect(retry!.deliveryKind, TarotReadingDeliveryKind.interpretation);
    expect(w.charge.alreadyCharged(session.id), isTrue);
    expect(w.transport.debits, 1, reason: 'idempotent replay, no 2nd debit');
    expect(w.server.balance, 0);
  });

  group('guards', () {
    test('A. NEW reading + insufficient gems: refused, no settle, no provider',
        () async {
      final w = await _World.create(gems: _cost - 1);
      final session = threeContrastSession(id: 'wave15_new_poor');
      final ai = _ai();

      final result = await w.open(session, w.interpretation(ai));

      expect(result, isNull);
      expect(ai.callCount, 0);
      expect(w.transport.postsFor(session.id), 0);
      expect(w.transport.debits, 0);
      expect(w.server.balance, _cost - 1);
    });

    test('C. double debit: the same reading is never debited twice', () async {
      final w = await _World.create(gems: _cost * 3);
      final session = threeContrastSession(id: 'wave15_double');
      w.transport.loseNextSettleResponse = true;
      expect(await w.open(session, w.interpretation(_ai())), isNull);

      final retry = await w.open(session, w.interpretation(_ai()));
      final again = await w.open(session, w.interpretation(_ai()));

      expect(retry, isNotNull);
      expect(again, isNotNull);
      expect(w.transport.debits, 1);
      expect(w.server.balance, _cost * 2);
    });

    test('D. normal path: settle response arrives → one debit, delivered',
        () async {
      final w = await _World.create(gems: _cost);
      final session = threeContrastSession(id: 'wave15_normal');

      final result = await w.open(session, w.interpretation(_ai()));

      expect(result, isNotNull);
      expect(w.charge.alreadyCharged(session.id), isTrue);
      expect(w.transport.postsFor(session.id), 1);
      expect(w.transport.debits, 1);
      expect(w.server.balance, 0);
    });

    test('CASE 2. abandoned + server NEVER debited + insufficient gems: '
        'server refuses the replay, no reading, no debit, no provider call',
        () async {
      final w = await _World.create(gems: _cost);
      final session = threeContrastSession(id: 'wave15_never_debited');
      w.transport.dropNextSettleRequest = true;
      expect(await w.open(session, w.interpretation(_ai())), isNull);
      expect(w.transport.postsFor(session.id), 0);
      expect(w.server.balance, _cost, reason: 'server never debited');
      // Gems spent elsewhere before the retry.
      w.server.balance = 0;
      await w.wallet.refresh();
      final opId = PaidAiOperationId.fromExisting('tarot', session.id);
      expect(PaidAiOperationStore(w.storage).byId(opId)?.status,
          PaidAiOperationStatus.abandoned);

      final ai = _ai();
      final retry = await w.open(session, w.interpretation(ai));

      expect(w.transport.postsFor(session.id), 1,
          reason: 'same-reading recovery asks the server');
      expect(retry, isNull, reason: 'server rejection is never success');
      expect(ai.callCount, 0, reason: 'no free provider call on rejection');
      expect(w.transport.debits, 0);
      expect(w.server.balance, 0);
      expect(w.charge.alreadyCharged(session.id), isFalse);
      expect(PaidAiOperationStore(w.storage).byId(opId)?.status,
          isNot(PaidAiOperationStatus.settled));
    });

    test('provider failure before delivery: no record, no settle, no charge',
        () async {
      final w = await _World.create(gems: _cost);
      final session = threeContrastSession(id: 'wave15_provider_fail');
      final completion = TarotReadingCompletion(
        charge: w.charge,
        interpretation: w.interpretation(_ai()),
      );

      final result = await completion.complete(
        session,
        load: () async => throw StateError('provider down'),
      );

      expect(result, isNull);
      expect(w.transport.postsFor(session.id), 0);
      expect(w.transport.debits, 0);
      expect(w.server.balance, _cost);
      expect(
        PaidAiOperationStore(w.storage)
            .byId(PaidAiOperationId.fromExisting('tarot', session.id)),
        isNull,
      );
    });

    test('successful (recovered) operation is final: reopening never refunds '
        'or re-debits', () async {
      final w = await _World.create(gems: _cost);
      final session = await _paidButResponseLost(w);
      expect(await w.open(session, w.interpretation(_ai())), isNotNull);

      final reopened = await w.open(session, w.interpretation(_ai()));
      await w.wallet.refresh();

      expect(reopened, isNotNull);
      expect(w.transport.postsFor(session.id), 2,
          reason: 'settled locally → no further server settle');
      expect(w.transport.debits, 1);
      expect(w.server.balance, 0, reason: 'no refund of a delivered reading');
      expect(w.wallet.balance, 0);
    });

    test('E. DIFFERENT reading: the lost-response record of reading 1 never '
        'lets reading 2 bypass insufficient gems', () async {
      final w = await _World.create(gems: _cost);
      await _paidButResponseLost(w);
      final other = threeContrastSession(id: 'wave15_other_reading');

      final result = await w.open(other, w.interpretation(_ai()));

      expect(result, isNull);
      expect(w.transport.postsFor(other.id), 0,
          reason: 'no payment record for reading 2 → no recovery attempt');
      expect(w.charge.alreadyCharged(other.id), isFalse);
      expect(w.transport.debits, 1, reason: 'still only reading 1 charged');
      expect(w.server.balance, 0);
    });

    test('F. owner isolation: user-a\'s paid reading never becomes free for '
        'user-b', () async {
      final a = await _World.create(gems: _cost);
      final session = await _paidButResponseLost(a);

      // user-b, 0 gems, on the same device storage, opens the same reading.
      final b = await _World.onStorage(a.storage, gems: 0);
      final bAi = _ai();
      final asB = await b.open(session, b.interpretation(bAi));

      expect(asB, isNull, reason: 'user-b has no settlement for this reading');
      expect(bAi.callCount, 0, reason: 'refused before any provider call');
      expect(b.charge.alreadyCharged(session.id), isFalse);
      expect(b.transport.debits, 0);
      expect(b.server.balance, 0);
      expect(a.transport.debits, 1);
      expect(a.server.balance, 0);
    });
  });
}
