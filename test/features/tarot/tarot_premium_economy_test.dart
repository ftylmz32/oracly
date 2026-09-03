/// Honest tarot gem/premium contract — free one-card, paid deeper spreads.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/features/daily_ritual/services/daily_ritual_reflections.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/premium/models/premium_models.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_completion.dart';
import 'package:oracly_new/features/tarot/first_session/tarot_first_reading.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/tarot_entry/tarot_entry_spread_choice.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late GemWalletService wallet;
  late TarotReadingCharge charge;
  late TarotReadingCompletion completion;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    wallet = GemWalletService(GemWalletStore(storage));
    charge = TarotReadingCharge(wallet, storage);
    completion = TarotReadingCompletion(charge: charge);
  });

  test('one-card, daily ritual, and first session stay free', () {
    expect(TarotEconomy.costFor(TarotSpreadType.single), isNull);
    expect(TarotEconomy.isFree(TarotFirstReading.spread), isTrue);
    expect(DailyRitualReflections.drawCta(), 'Kart çek');
    expect(OraclyFeatureRegistry.byId(OraclyFeatureId.tarot)?.requiresPremium, isFalse);
  });

  test('deeper spreads cost 20 gems and do not require Premium', () {
    for (final spread in [
      TarotSpreadType.threeCard,
      TarotSpreadType.fiveCard,
      TarotSpreadType.sevenCard,
    ]) {
      expect(TarotEconomy.costFor(spread), GemEconomy.tarotReading);
      expect(TarotEconomy.requiresPremium(spread), isFalse);
    }
    expect(
      TarotEntrySpreadChoice.offered().map((c) => c.type),
      containsAll([
        TarotSpreadType.single,
        TarotSpreadType.fiveCard,
        TarotSpreadType.sevenCard,
      ]),
    );
    expect(PremiumCatalogue.premiumExperiences, hasLength(3));
    expect(const UnavailablePremiumPurchase().isConfigured, isFalse);
    expect(PremiumCopy.ctaUnavailable, contains('henüz'));
    expect(PremiumDevOverride.isActive, isFalse);
    expect(GemsCopy.spendBody, contains('Tek kart ücretsizdir'));
    expect(PremiumCopy.gemNote(20), contains('Üç kart ve üzeri'));
  });

  test('single-card success does not deduct', () async {
    await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
    expect(
      await completion.complete(_session('free', TarotSpreadType.single)),
      isNotNull,
    );
    expect(wallet.balance, 50);
    expect(wallet.history.where((t) => t.amount < 0), isEmpty);
  });

  test('paid success deducts once; failure, cancel, and retry stay honest',
      () async {
    await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
    expect(
      await completion.complete(
        _session('fail'),
        load: () async => throw Exception('provider'),
      ),
      isNull,
    );
    expect(wallet.balance, 50);
    expect(
      await completion.complete(_session('cancel'), shouldCommit: () => false),
      isNull,
    );
    expect(wallet.balance, 50);
    expect(await completion.complete(_session('ok')), isNotNull);
    expect(wallet.balance, 30);
    expect(await completion.complete(_session('ok')), isNotNull);
    expect(wallet.balance, 30);
    expect(wallet.history.where((t) => t.amount < 0), hasLength(1));
  });

  test('empty wallet still receives a free one-card reading', () async {
    expect(
      await completion.complete(_session('empty', TarotSpreadType.single)),
      isNotNull,
    );
    expect(wallet.balance, 0);
    expect(
      await completion.complete(_session('blocked')),
      isNull,
    );
    expect(wallet.balance, 0);
  });
}

ReadingSession _session(String id, [TarotSpreadType? spread]) {
  final reveal = CardRevealSpread.forIndex(0);
  return ReadingSession(
    id: id,
    deckId: 'classic',
    spread: spread ?? TarotSpreadType.threeCard,
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
