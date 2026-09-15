/// HttpBillingEntitlementVerifier — the real POST /v1/billing/verify client.
/// Covers Android/iOS payload serialization and every response mapping.
/// Never invents `active` on a network/parse/auth failure.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/http_billing_entitlement_verifier.dart';

void main() {
  test('not configured skips the network call entirely', () async {
    var called = false;
    final verifier = HttpBillingEntitlementVerifier(
      verifyUrl: '',
      client: MockClient((request) async {
        called = true;
        return http.Response('', 200);
      }),
    );
    expect(verifier.isRemoteVerifierConfigured, isFalse);
    final result = await verifier.verify(
      platform: 'android',
      productId: 'app.oracly.premium.yearly',
      purchaseToken: 'token',
    );
    expect(called, isFalse);
    expect(result.status, PremiumVerifyStatus.unverified);
    expect(result.reason, 'provider_not_configured');
  });

  test('Android request serializes exactly platform/productId/purchaseToken, '
      'omitting transactionId when absent', () async {
    http.Request? seen;
    final verifier = HttpBillingEntitlementVerifier(
      verifyUrl: 'https://api.example.com/v1/billing/verify',
      client: MockClient((request) async {
        seen = request;
        return http.Response(jsonEncode({'status': 'active'}), 200);
      }),
    );
    final result = await verifier.verify(
      platform: 'android',
      productId: 'app.oracly.premium.yearly',
      purchaseToken: 'play-purchase-token',
    );
    expect(result.isActive, isTrue);
    final body = jsonDecode(seen!.body) as Map<String, dynamic>;
    expect(body, {
      'platform': 'android',
      'productId': 'app.oracly.premium.yearly',
      'purchaseToken': 'play-purchase-token',
    });
    expect(body.containsKey('transactionId'), isFalse);
  });

  test('iOS request serializes the JWS purchaseToken and transactionId', () async {
    http.Request? seen;
    final verifier = HttpBillingEntitlementVerifier(
      verifyUrl: 'https://api.example.com/v1/billing/verify',
      client: MockClient((request) async {
        seen = request;
        return http.Response(jsonEncode({'status': 'active'}), 200);
      }),
    );
    const jws = 'aaa.bbb.ccc';
    final result = await verifier.verify(
      platform: 'ios',
      productId: 'app.oracly.premium.monthly',
      purchaseToken: jws,
      transactionId: '2000000123456789',
    );
    expect(result.isActive, isTrue);
    final body = jsonDecode(seen!.body) as Map<String, dynamic>;
    expect(body, {
      'platform': 'ios',
      'productId': 'app.oracly.premium.monthly',
      'purchaseToken': jws,
      'transactionId': '2000000123456789',
    });
  });

  test('includes an authorization header from a real Firebase token, never '
      'an OpenAI-shaped key', () async {
    http.Request? seen;
    final verifier = HttpBillingEntitlementVerifier(
      verifyUrl: 'https://api.example.com/v1/billing/verify',
      accessTokenProvider: () async => 'firebase-id-token',
      client: MockClient((request) async {
        seen = request;
        return http.Response(jsonEncode({'status': 'active'}), 200);
      }),
    );
    await verifier.verify(
      platform: 'android',
      productId: 'app.oracly.premium.yearly',
      purchaseToken: 'token',
    );
    expect(seen!.headers['Authorization'], 'Bearer firebase-id-token');
  });

  test('an sk- shaped token is never attached as a bearer credential', () async {
    http.Request? seen;
    final verifier = HttpBillingEntitlementVerifier(
      verifyUrl: 'https://api.example.com/v1/billing/verify',
      accessTokenProvider: () async => 'sk-should-not-leak',
      client: MockClient((request) async {
        seen = request;
        return http.Response(jsonEncode({'status': 'active'}), 200);
      }),
    );
    await verifier.verify(
      platform: 'android',
      productId: 'app.oracly.premium.yearly',
      purchaseToken: 'token',
    );
    expect(seen!.headers.containsKey('Authorization'), isFalse);
  });

  test('maps every backend status faithfully', () async {
    Future<PremiumVerifyResult> withStatus(Map<String, dynamic> body) {
      final verifier = HttpBillingEntitlementVerifier(
        verifyUrl: 'https://api.example.com/v1/billing/verify',
        client: MockClient(
          (request) async => http.Response(jsonEncode(body), 200),
        ),
      );
      return verifier.verify(
        platform: 'android',
        productId: 'app.oracly.premium.yearly',
        purchaseToken: 'token',
      );
    }

    expect(
      (await withStatus({'status': 'active'})).status,
      PremiumVerifyStatus.active,
    );
    expect(
      (await withStatus({'status': 'inactive', 'reason': 'revoked'})).status,
      PremiumVerifyStatus.inactive,
    );
    expect(
      (await withStatus({'status': 'pending'})).status,
      PremiumVerifyStatus.pending,
    );
    expect(
      (await withStatus({'status': 'expired'})).status,
      PremiumVerifyStatus.expired,
    );
    expect(
      (await withStatus({'status': 'error'})).status,
      PremiumVerifyStatus.error,
    );
    expect(
      (await withStatus({'status': 'unverified', 'reason': 'bundle_mismatch'}))
          .status,
      PremiumVerifyStatus.unverified,
    );
  });

  test('HTTP 401 never grants — maps to unverified auth_required', () async {
    final verifier = HttpBillingEntitlementVerifier(
      verifyUrl: 'https://api.example.com/v1/billing/verify',
      client: MockClient((request) async => http.Response('', 401)),
    );
    final result = await verifier.verify(
      platform: 'android',
      productId: 'app.oracly.premium.yearly',
      purchaseToken: 'token',
    );
    expect(result.isActive, isFalse);
    expect(result.status, PremiumVerifyStatus.unverified);
    expect(result.reason, 'auth_required');
  });

  test('HTTP 5xx never grants — surfaces as a typed error, not active', () async {
    final verifier = HttpBillingEntitlementVerifier(
      verifyUrl: 'https://api.example.com/v1/billing/verify',
      client: MockClient((request) async => http.Response('', 503)),
    );
    final result = await verifier.verify(
      platform: 'android',
      productId: 'app.oracly.premium.yearly',
      purchaseToken: 'token',
    );
    expect(result.isActive, isFalse);
    expect(result.status, PremiumVerifyStatus.error);
    expect(result.reason, 'http_503');
  });

  test('network exception never grants — surfaces as network_or_parse', () async {
    final verifier = HttpBillingEntitlementVerifier(
      verifyUrl: 'https://api.example.com/v1/billing/verify',
      client: MockClient((request) async => throw Exception('boom')),
    );
    final result = await verifier.verify(
      platform: 'android',
      productId: 'app.oracly.premium.yearly',
      purchaseToken: 'token',
    );
    expect(result.isActive, isFalse);
    expect(result.status, PremiumVerifyStatus.error);
    expect(result.reason, 'network_or_parse');
  });

  test('malformed (non-JSON-object) body never grants', () async {
    final verifier = HttpBillingEntitlementVerifier(
      verifyUrl: 'https://api.example.com/v1/billing/verify',
      client: MockClient((request) async => http.Response('[]', 200)),
    );
    final result = await verifier.verify(
      platform: 'android',
      productId: 'app.oracly.premium.yearly',
      purchaseToken: 'token',
    );
    expect(result.isActive, isFalse);
    expect(result.status, PremiumVerifyStatus.error);
    expect(result.reason, 'invalid_response');
  });

  test('timeout never grants — a slow backend cannot fabricate active', () async {
    final verifier = HttpBillingEntitlementVerifier(
      verifyUrl: 'https://api.example.com/v1/billing/verify',
      client: MockClient((request) async {
        await Future<void>.delayed(const Duration(seconds: 25));
        return http.Response(jsonEncode({'status': 'active'}), 200);
      }),
    );
    final result = await verifier.verify(
      platform: 'android',
      productId: 'app.oracly.premium.yearly',
      purchaseToken: 'token',
    );
    expect(result.isActive, isFalse);
    expect(result.status, PremiumVerifyStatus.error);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
