/// Vision chambers (Coffee/Palm/Soulmate) vs gem balance — rule out zero-balance gate.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/economy/coffee_economy.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/models/paid_ai_operation.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_coordinator.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/palm/economy/palm_economy.dart';
import 'package:oracly_new/features/premium/economy/soul_mate_economy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shared economy: vision chambers are gem-free today', () {
    test('Coffee Palm Soulmate have no crystal price configured', () {
      expect(CoffeeEconomy.analysisCost, isNull);
      expect(PalmEconomy.analysisCost, isNull);
      expect(SoulMateEconomy.drawCost, isNull);
      expect(CoffeeEconomy.hasCost, isFalse);
      expect(PalmEconomy.hasCost, isFalse);
      expect(SoulMateEconomy.hasCost, isFalse);
    });
  });

  group('Zero balance cannot block free operations', () {
    late LocalStorage storage;
    late GemWalletService wallet;
    late PaidAiOperationCoordinator coordinator;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = LocalStorage(await SharedPreferences.getInstance());
      wallet = GemWalletService(GemWalletStore(storage));
      coordinator = PaidAiOperationCoordinator(wallet: wallet, storage: storage);
    });

    test('beginPaid with null cost succeeds at balance 0 without deduction', () async {
      expect(wallet.balance, 0);

      for (final feature in [
        (PaidAiFeature.palm, PalmEconomy.ledgerKey, GemsCopy.reasonPalm),
        (PaidAiFeature.coffee, CoffeeEconomy.ledgerKey, GemsCopy.reasonCoffee),
        (PaidAiFeature.soulmate, SoulMateEconomy.ledgerKey, GemsCopy.reasonSoulMate),
      ]) {
        final op = await coordinator.begin(
          feature: feature.$1,
          ledgerKey: feature.$2,
          reason: feature.$3,
          cost: null,
        );
        expect(op.isBillable, isFalse);
        expect(op.cost, 0);
        expect(op.status, PaidAiOperationStatus.settled);
        await coordinator.abandon(op.id);
        expect(wallet.balance, 0);
      }
    });

    test('failed generation abandons paid op without charging when cost enabled',
        () async {
      await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
      final op = await coordinator.begin(
        feature: PaidAiFeature.palm,
        ledgerKey: PalmEconomy.ledgerKey,
        reason: GemsCopy.reasonPalm,
        cost: 20,
      );
      expect(op.isBillable, isTrue);
      expect(wallet.balance, 50);
      await coordinator.abandon(op.id);
      expect(wallet.balance, 50);
      expect(
        coordinator.store.byId(op.id)?.status,
        PaidAiOperationStatus.abandoned,
      );
    });

    test('wallet cannot spend when balance is zero and cost is set', () {
      expect(wallet.balance, 0);
      expect(wallet.canSpend(20), isFalse);
    });
  });
}
