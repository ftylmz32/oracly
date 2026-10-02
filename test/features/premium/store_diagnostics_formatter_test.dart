/// Store diagnostics text and purchase-stream ring buffer never expose
/// receipts, JWS, tokens, transaction payloads, identity or credentials.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:oracly_new/features/premium/models/store_catalog_snapshot.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';
import 'package:oracly_new/features/premium/services/store_diagnostics_formatter.dart';
import 'package:oracly_new/features/premium/services/store_diagnostics_redaction.dart';
import 'package:oracly_new/features/premium/services/store_purchase_stream_diagnostics.dart';

import 'support/ios_storekit_fake.dart';

const _jws = 'eyJhbGciOiJFUzI1NiJ9.eyJ0cmFuc2FjdGlvbklkIjoiMSJ9.c2lnbmF0dXJl';
const _issuer = '57246542-96fe-1a63-e053-0824d011072a';
// Synthetic, split so secret scanners never mistake the fixture for a key.
const _keyLabel = 'PRIVATE ' 'KEY';
const _pem = '-----BEGIN $_keyLabel-----\nMIGTAgEAMBMGByqGSM49\n'
    '-----END $_keyLabel-----';
const _forbidden = [
  _jws,
  'eyJ',
  _issuer,
  'MIGTAgEAMBMGByqGSM49',
  'PRIVATE KEY',
  'sk-proj-abcdefghijklmnop',
  'abcdefghijklmnop',
  'Bearer',
  'tester@example.com',
  '2000000123456789',
  'server-token',
  'local-receipt-data',
  'txn-',
  'hunter2',
];

String get _hostile => 'Bearer $_jws $_pem issuer $_issuer key '
    'sk-proj-abcdefghijklmnop mail tester@example.com transactionId='
    '2000000123456789 token=server-token receipt=local-receipt-data '
    'password=hunter2 ${'Q' * 48}';

void main() {
  setUp(StorePurchaseStreamDiagnostics.reset);

  test('formatter redacts every forbidden shape in free-text fields', () {
    final text = StoreDiagnosticsFormatter.format(
      catalog: StoreCatalogSnapshot(
        at: DateTime.utc(2026, 10, 2),
        storeAvailable: true,
        requestedIds: [PremiumStoreCatalog.monthlyId, _jws],
        returnedIds: ['tester@example.com'],
        notFoundIds: [PremiumStoreCatalog.yearlyId],
        errorCode: 'code $_jws',
        errorMessage: _hostile,
        queryExceptionType: 'Ex $_issuer',
        attempt: 2,
      ),
      stream: const [],
      appVersion: '1.0.0',
      buildNumber: '10',
      platform: TargetPlatform.iOS,
    );
    for (final secret in _forbidden) {
      expect(text, isNot(contains(secret)), reason: 'leaked: $secret');
    }
    expect(text, contains('app: 1.0.0 (10)'));
    expect(text, contains(PremiumStoreCatalog.monthlyId));
    expect(text, contains('notFound: ${PremiumStoreCatalog.yearlyId}'));
    expect(text, contains('attempt: 2'));
    expect(text, contains('[redacted]'));
  });

  test('purchase-stream buffer keeps status/product only, never payloads', () {
    StorePurchaseStreamDiagnostics.recordListenerAttached();
    StorePurchaseStreamDiagnostics.recordPurchase(
      storeTransaction(
        PremiumStoreCatalog.yearlyId,
        PurchaseStatus.purchased,
        token: _jws,
      ),
    );
    StorePurchaseStreamDiagnostics.recordPurchase(
      storeTransaction('com.other.$_issuer', PurchaseStatus.error),
    );
    StorePurchaseStreamDiagnostics.recordStreamError(
      StateError('token=server-token $_jws'),
    );
    final text = StoreDiagnosticsFormatter.format(
      catalog: null,
      stream: StorePurchaseStreamDiagnostics.recent,
    );
    for (final secret in _forbidden) {
      expect(text, isNot(contains(secret)), reason: 'leaked: $secret');
    }
    expect(text, contains('catalog: not checked yet'));
    expect(text, contains('app: not-stamped (not-stamped)'));
    expect(
      text,
      contains('purchase status=purchased '
          'product=${PremiumStoreCatalog.yearlyId}'),
    );
    expect(text, contains('purchase status=error product=unrecognized'));
    expect(text, contains('streamError error=StateError'));
  });

  test('purchase-stream buffer is bounded, oldest dropped first', () {
    const extra = 5;
    for (var i = 0; i < StorePurchaseStreamDiagnostics.capacity + extra; i++) {
      StorePurchaseStreamDiagnostics.recordEmptyBatch();
    }
    StorePurchaseStreamDiagnostics.recordListenerAttached();
    final events = StorePurchaseStreamDiagnostics.recent;
    expect(events.length, StorePurchaseStreamDiagnostics.capacity);
    expect(events.last.kind, StorePurchaseStreamEventKind.listenerAttached);
    expect(() => events.add(events.first), throwsUnsupportedError);
  });

  test('redaction covers every shape even without the length cap', () {
    final text = StoreDiagnosticsRedaction.scrub(_hostile, maxLength: 4000);
    for (final secret in _forbidden) {
      expect(text, isNot(contains(secret)), reason: 'leaked: $secret');
    }
    expect(text, contains('password=[redacted]'));
  });

  test('id lists are capped', () {
    final text = StoreDiagnosticsFormatter.format(
      catalog: StoreCatalogSnapshot(
        at: DateTime.utc(2026, 10, 2),
        storeAvailable: true,
        returnedIds: [for (var i = 0; i < 12; i++) 'app.oracly.p$i'],
      ),
      stream: const [],
    );
    expect(text, contains('(+4 more)'));
    // Ids are sorted lexicographically, so p6..p9 are the overflow.
    expect(text, contains('app.oracly.p11'));
    expect(text, isNot(contains('app.oracly.p9')));
  });
}
