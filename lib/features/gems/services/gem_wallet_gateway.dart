/// Authenticated, purpose-specific server wallet commands.
library;

import '../../reading_operation/services/reading_operation_gateway.dart';

class GemServerResult {
  const GemServerResult({
    required this.balance,
    this.applied = false,
    this.idempotent = false,
    this.canonicalCost,
    this.serverDay,
  });

  final int balance;
  final bool applied;
  final bool idempotent;
  final int? canonicalCost;
  final String? serverDay;
}

class RewardedAdClaim {
  const RewardedAdClaim(this.customData, this.expiresAtMs);
  final String customData;
  final int expiresAtMs;
}

class GemWalletGateway {
  GemWalletGateway(this._send);
  final ReadingOperationSender _send;

  Future<GemServerResult?> balance() => _request('GET', '/v1/gems/balance');
  Future<GemServerResult?> starterGrant(String key) =>
      _request('POST', '/v1/gems/starter-grant', key: key);

  Future<GemServerResult?> dailyReward(String key) =>
      _request('POST', '/v1/gems/daily-reward', key: key);

  Future<GemServerResult?> settleTarot(String operationId, String key) =>
      _request('POST', '/v1/gems/tarot/$operationId/settle', key: key);

  Future<RewardedAdClaim?> rewardedAdClaim() async {
    final wire = await _send('POST', '/v1/gems/rewarded-ad/claim', const <String, Object>{});
    if (wire == null || wire.statusCode < 200 || wire.statusCode >= 300) return null;
    final data = wire.json?['data'];
    if (data is! Map || data['customData'] is! String || data['expiresAtMs'] is! int) return null;
    return RewardedAdClaim(data['customData'] as String, data['expiresAtMs'] as int);
  }

  Future<GemServerResult?> _request(
    String method,
    String path, {
    String? key,
  }) async {
    final wire = await _send(
      method,
      path,
      key == null ? null : <String, Object>{'idempotencyKey': key},
    );
    if (wire == null) {
      print('[GemWalletGateway] $method $path — no wire (auth/AppCheck?)');
      return null;
    }
    if (wire.statusCode < 200 || wire.statusCode >= 300) {
      print(
        '[GemWalletGateway] $method $path — HTTP ${wire.statusCode}',
      );
      return null;
    }
    final data = wire.json?['data'];
    if (data is! Map) {
      print('[GemWalletGateway] $method $path — missing data map');
      return null;
    }
    final balance = _readBalance(data['balance']);
    if (balance == null) {
      print(
        '[GemWalletGateway] $method $path — bad balance=${data['balance']}',
      );
      return null;
    }
    print('[GemWalletGateway] $method $path — OK balance=$balance');
    return GemServerResult(
      balance: balance,
      applied: data['granted'] == true || data['settled'] == true,
      idempotent: data['idempotent'] == true,
      canonicalCost: data['canonicalCost'] is int
          ? data['canonicalCost'] as int
          : null,
      serverDay: data['serverDay'] as String?,
    );
  }

  static int? _readBalance(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return null;
  }
}
