import 'dart:convert';

import 'reading_operation_gateway.dart';

class ReadingStagedImageGateway {
  ReadingStagedImageGateway(this._send);

  final ReadingOperationSender _send;

  Future<bool> stage({
    required String operationId,
    required List<int> bytes,
    required String mimeType,
    String? handSide,
    String? slot,
  }) async {
    final wire = await _send(
      'POST',
      '/v1/reading-operations/$operationId/staged-image',
      <String, Object>{
        'mimeType': mimeType,
        'imageBase64': base64Encode(bytes),
        'handSide': ?handSide,
        'slot': ?slot,
      },
    );
    final data = wire?.json?['data'];
    return wire?.statusCode == 200 && data is Map && data['staged'] == true;
  }
}
