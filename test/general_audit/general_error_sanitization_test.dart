/// G0 — global error sanitization: no provider / transport / credential text.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/analytics/product_analytics_params.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/network/network_exception.dart';
import 'package:oracly_new/core/security/ai_error_sanitizer.dart';

const _fallback = 'calm fallback';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('technical and credential text never reaches the user', () {
    for (final raw in [
      'OpenAI returned an error',
      'GPT-4o refused the request',
      'HTTP 500 Internal Server Error',
      'Exception: boom',
      'Stack trace: #0 main (package:oracly_new/main.dart:1)',
      'JSON parse failed at line 1',
      'Unexpected token < in JSON at position 0',
      'FormatException: Unexpected character',
      'Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.c2ln',
      'token eyJhbGciOiJSUzI1NiIsImtpZCI6IjEifQ.eyJ1aWQiOiJ4In0.c2ln',
      'Authorization: Bearer abc123',
      'API key invalid',
      'api_key=sk-live-123',
      'Cloud Run revision oracly-ai-00042-abc failed',
      'upstream oracly-ai-xyz-uc.a.run.app unavailable',
      'Firebase ID token expired',
    ]) {
      expect(AiErrorSanitizer.guard(raw, fallback: _fallback), _fallback,
          reason: raw);
    }
  });

  test('analytics params never carry ids, tokens or reading bodies', () {
    final safe = ProductAnalyticsParams.sanitize({
      'feature': 'coffee',
      'operation': 'analysis',
      'operation_id': '0123456789abcdef0123456789abcdef',
      'operationId': '0123456789abcdef0123456789abcdef',
      'purchase_token': 'synthetic',
      'narrative': 'I dreamt of a river.',
      'reason': 'My private dream about a river and my mother.',
    });
    expect(safe, {'feature': 'coffee', 'operation': 'analysis'});
  });

  test('calm actionable copy survives; offline stays distinguishable', () {
    const calm = 'Bağlantı şu an kurulamadı. Birazdan yeniden dene.';
    expect(AiErrorSanitizer.guard(calm, fallback: _fallback), calm);
    expect(
      AiErrorSanitizer.publicMessage(
        error: const NetworkException(
          kind: NetworkErrorKind.noConnection,
          message: 'SocketException: Failed host lookup',
        ),
      ),
      ResilienceCopy.offline,
    );
    expect(AiErrorSanitizer.guard('offline'), ResilienceCopy.offline);
    expect(AiErrorSanitizer.guard('timeout'), ResilienceCopy.slowResponse);
    expect(ResilienceCopy.offline, isNot(ResilienceCopy.aiUnavailable));
  });
}
