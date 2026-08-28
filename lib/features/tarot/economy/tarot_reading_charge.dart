/// Charges tarot gems once, after a reading is actually committed.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../../../core/services/analytics_service.dart';
import '../../gems/copy/gems_copy.dart';
import '../../gems/models/paid_ai_operation.dart';
import '../../gems/services/gem_action_charge.dart';
import '../../gems/services/gem_wallet_service.dart';
import '../../gems/services/paid_ai_operation_coordinator.dart';
import '../../gems/services/paid_ai_operation_id.dart';
import '../domain/models/tarot_spread.dart';
import 'tarot_economy.dart';

class TarotReadingCharge {
  TarotReadingCharge(
    GemWalletService wallet,
    LocalStorage storage, {
    AnalyticsService? analytics,
  })  : _charge = GemActionCharge(
          wallet,
          storage,
          ledgerKey: _key,
        ),
        _ops = PaidAiOperationCoordinator(
          wallet: wallet,
          storage: storage,
        ),
        _analytics = analytics;

  static const _key = 'tarot_gem_charged_sessions';

  final GemActionCharge _charge;
  final PaidAiOperationCoordinator _ops;
  final AnalyticsService? _analytics;

  String _opId(String sessionId) =>
      PaidAiOperationId.fromExisting('tarot', sessionId);

  bool alreadyCharged(String sessionId) {
    final id = _opId(sessionId);
    return _charge.alreadyCharged(id) || _charge.alreadyCharged(sessionId);
  }

  bool canAfford(TarotSpreadType spread, {required String sessionId}) {
    if (alreadyCharged(sessionId)) return true;
    final cost = TarotEconomy.costFor(spread);
    if (cost == null || cost <= 0) return true;
    return _charge.canAfford(cost);
  }

  /// Provider produced usable content — persist before settle for resume.
  Future<void> markProviderOk(
    String sessionId, {
    required TarotSpreadType spread,
  }) async {
    final cost = TarotEconomy.costFor(spread);
    if (cost == null || cost <= 0) return;
    final op = await _ops.begin(
      feature: PaidAiFeature.tarot,
      ledgerKey: _key,
      reason: GemsCopy.reasonTarot,
      cost: cost,
      existingId: sessionId,
    );
    await _ops.markProviderOk(op.id);
  }

  /// Cancel without charge when content was never delivered.
  Future<void> abandon(
    String sessionId, {
    required TarotSpreadType spread,
  }) async {
    final cost = TarotEconomy.costFor(spread);
    if (cost == null || cost <= 0) return;
    final id = _opId(sessionId);
    await _ops.abandon(id);
  }

  /// No [spread] → listed paid price (tests and explicit paid settle).
  Future<bool> commit(String sessionId, {TarotSpreadType? spread}) async {
    final cost = spread == null
        ? TarotEconomy.readingCost
        : TarotEconomy.costFor(spread);
    final firstCharge = !alreadyCharged(sessionId);
    final op = await _ops.begin(
      feature: PaidAiFeature.tarot,
      ledgerKey: _key,
      reason: GemsCopy.reasonTarot,
      cost: cost,
      existingId: sessionId,
    );
    final ok = await _ops.completeAfterProvider(op);
    if (ok && firstCharge && cost != null && cost > 0 && op.isBillable) {
      _analytics?.logGemPurchaseSuccess(reason: 'tarot');
    }
    return ok;
  }
}
