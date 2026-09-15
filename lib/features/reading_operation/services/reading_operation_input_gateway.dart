/// Save/read a ReadingOperation's durable structured input (Soulmate).
/// No AI call happens here — this is pure storage plumbing.
library;

import 'reading_operation_gateway.dart';

class ReadingOperationInputGateway {
  ReadingOperationInputGateway({required this._send});

  final ReadingOperationSender _send;

  static const _allowedKeys = {'name', 'birthIso', 'gender', 'intention'};

  Future<bool> save({
    required String operationId,
    required Map<String, String> fields,
  }) async {
    final body = <String, Object>{
      for (final entry in fields.entries)
        if (_allowedKeys.contains(entry.key) && entry.value.isNotEmpty) entry.key: entry.value,
    };
    try {
      final wire = await _send(
        'POST',
        '/v1/reading-operations/$operationId/input',
        body,
      );
      return wire != null && wire.statusCode >= 200 && wire.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, String>?> get(String operationId) async {
    try {
      final wire = await _send(
        'GET',
        '/v1/reading-operations/$operationId/input',
        null,
      );
      if (wire == null || wire.statusCode < 200 || wire.statusCode >= 300) return null;
      final data = wire.json?['data'];
      if (data is! Map) return null;
      final fields = data['fields'];
      if (fields is! Map) return null;
      final out = <String, String>{};
      for (final entry in fields.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && _allowedKeys.contains(key) && value is String) {
          out[key] = value;
        }
      }
      return out;
    } catch (_) {
      return null;
    }
  }
}
