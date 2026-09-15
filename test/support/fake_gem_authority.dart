import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_gateway.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';

class FakeGemAuthority {
  FakeGemAuthority({this.balance = 0, String? serverDay})
      : serverDay = serverDay ?? _dayKey(DateTime.now().toUtc());

  int balance;
  String serverDay;
  bool online = true;
  int requests = 0;
  final Set<String> _posted = <String>{};

  static String _dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  GemWalletService wallet(LocalStorage storage) => GemWalletService(
        GemWalletStore(storage),
        gateway: GemWalletGateway(send),
      );

  Future<ReadingOperationWire?> send(
    String method,
    String path,
    Map<String, Object>? body,
  ) async {
    requests += 1;
    if (!online) return null;
    if (path == '/v1/gems/balance') return _ok({'balance': balance});
    if (path == '/v1/gems/starter-grant') {
      final first = _posted.add('starter');
      if (first) balance += 20;
      return _ok({'balance': balance, 'granted': first, 'idempotent': !first});
    }
    if (path == '/v1/gems/daily-reward') {
      final first = _posted.add('daily:$serverDay');
      if (first) balance += 50;
      return _ok({
        'balance': balance,
        'granted': first,
        'idempotent': !first,
        'serverDay': serverDay,
      });
    }
    if (path.startsWith('/v1/gems/tarot/') && path.endsWith('/settle')) {
      final operationId = path.split('/')[4];
      final first = !_posted.contains('tarot:$operationId');
      if (first && balance < 20) {
        return const ReadingOperationWire(statusCode: 409, json: {});
      }
      if (first) {
        _posted.add('tarot:$operationId');
        balance -= 20;
      }
      return _ok({
        'balance': balance,
        'settled': true,
        'idempotent': !first,
        'canonicalCost': 20,
      });
    }
    return const ReadingOperationWire(statusCode: 404, json: {});
  }

  ReadingOperationWire _ok(Map<String, Object> data) =>
      ReadingOperationWire(statusCode: 200, json: {'data': data});
}
