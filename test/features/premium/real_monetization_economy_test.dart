/// Real product economy — no invented prices, fail-closed gem spend.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/economy/coffee_economy.dart';
import 'package:oracly_new/features/dream/economy/dream_economy.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/services/gem_action_charge.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/palm/economy/palm_economy.dart';
import 'package:oracly_new/features/premium/economy/soul_mate_economy.dart';
import 'package:oracly_new/features/premium/models/premium_models.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_completion.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late GemWalletService wallet;
  late GemActionCharge charge;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    wallet = GemWalletService(GemWalletStore(storage));
    charge = GemActionCharge(wallet, storage, ledgerKey: 'test_ledger');
  });

  test('free surfaces have no invented gem price or membership wall', () {
    expect(CoffeeEconomy.analysisCost, isNull);
    expect(PalmEconomy.analysisCost, isNull);
    expect(DreamEconomy.analysisCost, isNull);
    expect(SoulMateEconomy.drawCost, isNull);
    expect(
      PremiumCatalogue.includedCapabilities.map((b) => b.title),
      containsAll([
        PremiumCopy.benefitCoffeeTitle,
        PremiumCopy.benefitPalmTitle,
        PremiumCopy.benefitDiscoveryTitle,
        PremiumCopy.benefitAtmosphereTitle,
      ]),
    );
    expect(
      PremiumCatalogue.includedCapabilities.map((b) => b.title),
      isNot(contains(PremiumCopy.benefitOrTitle)),
    );
    expect(PremiumCatalogue.premiumExperiences, hasLength(3));
    expect(
      PremiumCatalogue.premiumExperiences.map((b) => b.title),
      contains(PremiumCopy.benefitJourneyTitle),
    );
    expect(PremiumCopy.whatTitle, 'NEDİR BU KATMAN');
    expect(PremiumCopy.whyTitle, 'NEDEN VAR');
  });

  test('only a configured tarot reading spends gems', () {
    expect(TarotEconomy.readingCost, GemEconomy.tarotReading);
    expect(GemEconomy.tarotReading, 20);
    expect(TarotEconomy.costFor(TarotSpreadType.single), isNull);
    expect(TarotEconomy.costFor(TarotSpreadType.threeCard), 20);
  });

  test('insufficient gems never deducts', () async {
    expect(await charge.commit(actionId: 'a', cost: 20, reason: 'test'), isFalse);
    expect(wallet.balance, 0);
    expect(charge.alreadyCharged('a'), isFalse);
  });

  test('provider success deducts once', () async {
    await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
    expect(await charge.commit(actionId: 'ok', cost: 20, reason: 'test'), isTrue);
    expect(wallet.balance, 30);
    expect(
      await charge.commit(actionId: 'ok', cost: 20, reason: 'test'),
      isTrue,
    );
    expect(wallet.balance, 30);
  });

  test('null cost never deducts', () async {
    await wallet.earn(amount: 20, reason: GemsCopy.reasonStarter);
    expect(
      await charge.commit(actionId: 'free', cost: null, reason: 'test'),
      isTrue,
    );
    expect(wallet.balance, 20);
  });

  test('duplicate tap is blocked by the busy wallet', () async {
    await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
    final first = wallet.spend(amount: 20, reason: GemsCopy.reasonTarot);
    expect(
      () => wallet.spend(amount: 20, reason: GemsCopy.reasonTarot),
      throwsA(isA<GemSpendException>()),
    );
    await first;
    expect(wallet.balance, 30);
  });

  test('tarot provider failure is free; retry charges once', () async {
    final tarot = TarotReadingCharge(wallet, storage);
    final completion = TarotReadingCompletion(charge: tarot);
    await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
    expect(
      await completion.complete(
        _session('fail'),
        load: () async => throw Exception('provider'),
      ),
      isNull,
    );
    expect(wallet.balance, 50);
    expect(await completion.complete(_session('fail')), isNotNull);
    expect(wallet.balance, 30);
  });

  test('cancel before commit does not charge', () async {
    final tarot = TarotReadingCharge(wallet, storage);
    final completion = TarotReadingCompletion(charge: tarot);
    await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
    expect(
      await completion.complete(_session('cancel'), shouldCommit: () => false),
      isNull,
    );
    expect(wallet.balance, 50);
  });

  test('purchase stays unavailable without store billing', () {
    expect(const UnavailablePremiumPurchase().isConfigured, isFalse);
    expect(PremiumCopy.ctaUnavailable, contains('henüz'));
    expect(PremiumCopy.planPricePending, isNot(contains('₺')));
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
