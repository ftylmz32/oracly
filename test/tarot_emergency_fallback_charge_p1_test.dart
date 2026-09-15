/// P1 — completed tarot readings charge exactly once, including fallback.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/services/gem_starter_grant.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_completion.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_gem_authority.dart';

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
    authority = FakeGemAuthority();
    wallet = authority.wallet(storage);
    charge = TarotReadingCharge(wallet, storage);
    completion = TarotReadingCompletion(charge: charge);
  });

  test('normal reading spends exactly 20 gems once', () async {
    authority.balance = 50;
    await wallet.refresh();
    final content = await completion.complete(_session('normal'));
    expect(content, isNotNull);
    expect(content!.generalMeaning.trim(), isNotEmpty);
    expect(wallet.balance, 30);
  });

  test('provider failure does not spend gems', () async {
    authority.balance = 50;
    await wallet.refresh();
    final content = await completion.complete(
      _session('fallback'),
      load: () async => throw Exception('interpretation engine failed'),
    );
    expect(content, isNull);
    expect(wallet.balance, 50);
    expect(charge.alreadyCharged('fallback'), isFalse);
  });

  test('retry after failure charges once on success', () async {
    authority.balance = 50;
    await wallet.refresh();
    expect(
      await completion.complete(
        _session('retry'),
        load: () async => throw Exception('first fail'),
      ),
      isNull,
    );
    expect(wallet.balance, 50);
    expect(await completion.complete(_session('retry')), isNotNull);
    expect(wallet.balance, 30);
  });

  test('charge failure does not present a completed reading', () async {
    final content = await completion.complete(_session('unpaid'));
    expect(content, isNull);
    expect(wallet.balance, 0);
    expect(charge.alreadyCharged('unpaid'), isFalse);
  });

  test('duplicate retry does not spend a second 20', () async {
    authority.balance = 50;
    await wallet.refresh();
    final first = await completion.complete(_session('dup'));
    final retry = await completion.complete(
      _session('dup'),
      load: () async => throw Exception('retry after fallback'),
    );
    expect(first, isNotNull);
    expect(retry, isNotNull);
    expect(wallet.balance, 30);
  });

  test('insufficient balance never goes negative', () async {
    authority.balance = 10;
    await wallet.refresh();
    expect(await completion.complete(_session('short')), isNull);
    expect(wallet.balance, 10);
    expect(wallet.balance, greaterThanOrEqualTo(0));
    expect(charge.alreadyCharged('short'), isFalse);
  });

  test('first-reading starter grant of +20 still funds one tarot', () async {
    final starter = GemStarterGrant(wallet, storage);
    expect(GemEconomy.starterGrant, 20);
    expect(await starter.ensureOnce(), isTrue);
    expect(wallet.balance, 20);
    expect(await completion.complete(_session('first')), isNotNull);
    expect(wallet.balance, 0);
    expect(await starter.ensureOnce(), isFalse);
    expect(wallet.balance, 0);
  });

  test('cancel or back before commit does not charge', () async {
    authority.balance = 50;
    await wallet.refresh();
    final content = await completion.complete(
      _session('cancel'),
      shouldCommit: () => false,
    );
    expect(content, isNull);
    expect(wallet.balance, 50);
    expect(charge.alreadyCharged('cancel'), isFalse);
  });
}

ReadingSession _session(
  String id, {
  TarotSpreadType spread = TarotSpreadType.threeCard,
}) {
  final reveal = CardRevealSpread.forIndex(0);
  return ReadingSession(
    id: id,
    deckId: 'classic',
    spread: spread,
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
