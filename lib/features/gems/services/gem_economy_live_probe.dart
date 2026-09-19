/// Sideload-only gem economy live probe — never enabled in store defines.
library;

import '../controllers/gem_wallet_controller.dart';
import '../economy/gem_economy.dart';
import 'gem_wallet_service.dart';
import 'paid_ai_operation_id.dart';

/// Runs against the real backend when [enabled] (dart-define).
abstract final class GemEconomyLiveProbe {
  GemEconomyLiveProbe._();

  static const enabled = bool.fromEnvironment('ORACLY_GEM_ECONOMY_PROBE');

  static Future<void> runIfEnabled({
    required GemWalletService wallet,
    required GemWalletController controller,
  }) async {
    if (!enabled) return;
    print('[GemProbe] start authoritative=${controller.authoritative} '
        'balance=${controller.displayBalance}');
    if (!controller.authoritative) {
      await controller.reload();
    }
    final b0 = wallet.cachedBalance;
    print('[GemProbe] B0=$b0');
    if (b0 == null) {
      print('[GemProbe] FAIL no authoritative balance');
      return;
    }

    final daily1 = await wallet.claimDaily(
      idempotencyKey: 'probe-daily-reward-v1',
    );
    print(
      '[GemProbe] daily1 balance=${daily1?.balance} '
      'applied=${daily1?.applied} idempotent=${daily1?.idempotent} '
      'day=${daily1?.serverDay}',
    );
    if (daily1 != null) {
      await controller.acceptAuthoritativeBalance(daily1.balance);
    }
    final b1 = wallet.cachedBalance;
    print('[GemProbe] B1=$b1');

    final daily2 = await wallet.claimDaily(
      idempotencyKey: 'probe-daily-reward-v1-repeat',
    );
    print(
      '[GemProbe] daily2 balance=${daily2?.balance} '
      'applied=${daily2?.applied} idempotent=${daily2?.idempotent}',
    );
    if (daily2 != null) {
      await controller.acceptAuthoritativeBalance(daily2.balance);
    }
    final b2 = wallet.cachedBalance;
    if (b1 != null && b2 != null && b2 != b1) {
      print('[GemProbe] FAIL daily not idempotent B1=$b1 B2=$b2');
    } else {
      print('[GemProbe] daily idempotent OK B2=$b2');
    }

    final opId = PaidAiOperationId.create('tarot-probe');
    final settle1 = await wallet.settleTarot(
      operationId: opId,
      idempotencyKey: 'probe-tarot-settle-v1',
    );
    print(
      '[GemProbe] settle1 balance=${settle1?.balance} '
      'applied=${settle1?.applied} idempotent=${settle1?.idempotent} '
      'cost=${settle1?.canonicalCost}',
    );
    if (settle1 != null) {
      await controller.acceptAuthoritativeBalance(settle1.balance);
    }
    final b3 = wallet.cachedBalance;
    print('[GemProbe] B3=$b3');
    if (b2 != null &&
        b3 != null &&
        settle1?.applied == true &&
        settle1?.idempotent != true &&
        b3 != b2 - GemEconomy.tarotReading) {
      print('[GemProbe] FAIL settle debit expected ${b2 - GemEconomy.tarotReading}');
    }

    final settle2 = await wallet.settleTarot(
      operationId: opId,
      idempotencyKey: 'probe-tarot-settle-v1-repeat',
    );
    print(
      '[GemProbe] settle2 balance=${settle2?.balance} '
      'applied=${settle2?.applied} idempotent=${settle2?.idempotent}',
    );
    if (settle2 != null) {
      await controller.acceptAuthoritativeBalance(settle2.balance);
    }
    final b4 = wallet.cachedBalance;
    if (b3 != null && b4 != null && b4 != b3) {
      print('[GemProbe] FAIL settle not idempotent B3=$b3 B4=$b4');
    } else {
      print('[GemProbe] settle idempotent OK B4=$b4');
    }
    print(
      '[GemProbe] DONE controller=${controller.formatted} '
      'authoritative=${controller.authoritative}',
    );
  }
}
