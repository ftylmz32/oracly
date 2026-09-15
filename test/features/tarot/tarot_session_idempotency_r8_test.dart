/// R8 — Tarot session identity binds provider Idempotency-Key; charge once.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_binder.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_id.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_completion.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/fake_gem_authority.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late GemWalletService wallet;
  late TarotReadingCharge charge;
  late TarotReadingCompletion completion;
  late FakeGemAuthority authority;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    authority = FakeGemAuthority(balance: 100);
    wallet = authority.wallet(storage);
    await wallet.refresh();
    charge = TarotReadingCharge(wallet, storage);
    completion = TarotReadingCompletion(charge: charge);
  });

  test('retry binds the same session Idempotency-Key', () async {
    final keys = <String?>[];
    Future<AiReadingContent> load() async {
      keys.add(PaidAiOperationBinder.idempotencyKey);
      return AiReadingCatalogue.forIndex(0);
    }

    final session = _session('session-r8-stable');
    expect(await completion.complete(session, load: load), isNotNull);
    expect(await completion.complete(session, load: load), isNotNull);

    final expected = PaidAiOperationId.fromExisting('tarot', session.id);
    expect(keys, [expected, expected]);
    expect(authority.balance, 80);
  });

  test('provider timeout retry does not redraw session or double charge',
      () async {
    var calls = 0;
    final session = _session('session-r8-timeout');
    expect(
      await completion.complete(
        session,
        load: () async {
          calls += 1;
          throw Exception('timeout');
        },
      ),
      isNull,
    );
    expect(authority.balance, 100);
    expect(calls, 1);

    final ok = await completion.complete(
      session,
      load: () async {
        calls += 1;
        return AiReadingCatalogue.forIndex(0);
      },
    );
    expect(ok, isNotNull);
    expect(session.id, 'session-r8-timeout');
    expect(calls, 2);
    expect(authority.balance, 80);
  });

  test('explicit new session id is a new economic intent', () async {
    Future<AiReadingContent> load() async => AiReadingCatalogue.forIndex(0);
    expect(await completion.complete(_session('s1'), load: load), isNotNull);
    expect(await completion.complete(_session('s2'), load: load), isNotNull);
    expect(authority.balance, 60);
  });
}

ReadingSession _session(String id) {
  final reveal = CardRevealSpread.forIndex(0);
  return ReadingSession(
    id: id,
    deckId: 'classic',
    spread: TarotSpreadType.threeCard,
    intention: const TarotIntention(text: 'Genel rehberlik'),
    shuffleSeed: 7,
    startedAt: DateTime(2026, 8, 9),
    drawnCards: [
      TarotDrawnCard(
        card: reveal.card,
        positionIndex: 0,
        isReversed: false,
        positionLabel: 'Şimdi',
      ),
    ],
  );
}
