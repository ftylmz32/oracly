/// P4 gem economy UX — clarity without changing prices.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/coffee/economy/coffee_economy.dart';
import 'package:oracly_new/features/dream/economy/dream_economy.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/palm/economy/palm_economy.dart';
import 'package:oracly_new/features/premium/economy/soul_mate_economy.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('canonical amounts stay fixed', () {
    expect(GemEconomy.starterGrant, 20);
    expect(GemEconomy.dailyReward, 50);
    expect(GemEconomy.tarotReading, 20);
    expect(TarotEconomy.readingCost, GemEconomy.tarotReading);
    expect(GemEconomy.starterGrant, GemEconomy.tarotReading);
  });

  test('only deeper tarot spends gems; other chambers stay free', () {
    expect(TarotEconomy.costFor(TarotSpreadType.single), isNull);
    expect(TarotEconomy.costFor(TarotSpreadType.threeCard), 20);
    expect(TarotEconomy.requiresPremium(TarotSpreadType.threeCard), isFalse);
    expect(CoffeeEconomy.analysisCost, isNull);
    expect(PalmEconomy.analysisCost, isNull);
    expect(DreamEconomy.analysisCost, isNull);
    expect(SoulMateEconomy.drawCost, isNull);
  });

  test('confirm copy answers spend / why / balance', () {
    final body = GemsCopy.confirmBodyPurpose(
      cost: GemEconomy.tarotReading,
      balance: 50,
      reason: GemsCopy.reasonTarot,
    );
    expect(body, contains(GemsCopy.reasonTarot));
    expect(body, contains(GemsCopy.costLabel(20)));
    expect(body, contains(GemsCopy.costLabel(50)));
    expect(body.toLowerCase(), contains('onaylamadan'));
    expect(GemsCopy.confirmTitle.toLowerCase(), contains('onayla'));
    expect(GemsCopy.claimReceived(50), contains('50'));
  });

  test('literacy copy names earn, spend, and premium separation', () {
    expect(GemsCopy.earnBody, contains('20'));
    expect(GemsCopy.earnBody, contains('50'));
    expect(GemsCopy.spendBody.toLowerCase(), contains('20'));
    expect(GemsCopy.spendBody.toLowerCase(), contains('\u00fccretsiz'));
    expect(GemsCopy.shopHonesty.toLowerCase(), contains('premium'));
    expect(GemsCopy.shopHonesty.toLowerCase(), contains('paket'));
    expect(GemsCopy.shopHonesty, isNot(contains('\u20ba')));
    expect(GemsCopy.tarotLabel.toLowerCase(), contains('\u00fc\u00e7 kart'));
  });

  test('insufficient path points to gems, not a fake shop', () {
    expect(GemsCopy.insufficient, 'Yeterli m\u00fccevherin yok.');
    expect(GemsCopy.insufficientCost(20), contains('20'));
    expect(GemsCopy.openGemsAction, 'M\u00fccevherler');
  });
}
