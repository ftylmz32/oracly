/// Monetization boundaries do not create a second Gem authority.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/economy/coffee_economy.dart';
import 'package:oracly_new/features/gems/services/gem_action_charge.dart';
import 'package:oracly_new/features/palm/economy/palm_economy.dart';
import 'package:oracly_new/features/premium/economy/soul_mate_economy.dart';
import '../../support/fake_gem_authority.dart';

void main() {
  test('free vision surfaces retain no invented Gem price', () {
    expect(CoffeeEconomy.analysisCost, isNull);
    expect(PalmEconomy.analysisCost, isNull);
    expect(SoulMateEconomy.drawCost, isNull);
  });

  test('retired generic charge cannot mutate server snapshot', () async {
    final storage = LocalStorage.ephemeral();
    final authority = FakeGemAuthority(balance: 50);
    final wallet = authority.wallet(storage);
    await wallet.refresh();
    final charge = GemActionCharge(wallet, storage, ledgerKey: 'legacy');
    expect(await charge.commit(actionId: 'old', cost: 20, reason: 'old'), isFalse);
    expect(wallet.balance, 50);
    expect(authority.balance, 50);
  });

  test('null-cost compatibility action remains free', () async {
    final storage = LocalStorage.ephemeral();
    final wallet = FakeGemAuthority(balance: 20).wallet(storage);
    await wallet.refresh();
    final charge = GemActionCharge(wallet, storage, ledgerKey: 'free');
    expect(await charge.commit(actionId: 'free', cost: null, reason: 'free'), isTrue);
    expect(wallet.balance, 20);
  });
}
