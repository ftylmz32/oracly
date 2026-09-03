/// HTTP billing verify client — posts tokens; never invents [active].
///
/// When the backend stub replies unverified / provider_not_configured,
/// that is honest: Apple/Google validation is not implemented yet.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/premium_verify_result.dart';
import 'premium_entitlement_verifier.dart';

class HttpBillingEntitlementVerifier implements PremiumEntitlementVerifier {
  HttpBillingEntitlementVerifier({
    required this.verifyUrl,
    this.accessTokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String verifyUrl;
  final Future<String?> Function()? accessTokenProvider;
  final http.Client _client;

  @override
  bool get isRemoteVerifierConfigured => verifyUrl.trim().isNotEmpty;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    if (!isRemoteVerifierConfigured) {
      return PremiumVerifyResult.unverified('provider_not_configured');
    }
    try {
      final headers = <String, String>{'content-type': 'application/json'};
      final token = (await accessTokenProvider?.call())?.trim();
      if (token != null && token.isNotEmpty && !token.startsWith('sk-')) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await _client
          .post(
            Uri.parse(verifyUrl),
            headers: headers,
            body: jsonEncode({
              'platform': platform,
              'productId': productId,
              'purchaseToken': purchaseToken,
              'transactionId': ?transactionId,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        return PremiumVerifyResult.unverified('auth_required');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return PremiumVerifyResult.error('http_${response.statusCode}');
      }
      final body = jsonDecode(response.body);
      if (body is! Map) {
        return PremiumVerifyResult.error('invalid_response');
      }
      return _map(body);
    } catch (_) {
      return PremiumVerifyResult.error('network_or_parse');
    }
  }

  PremiumVerifyResult _map(Map<dynamic, dynamic> body) {
    final status = (body['status'] ?? '').toString().toLowerCase();
    final reason = body['reason']?.toString();
    return switch (status) {
      'active' => PremiumVerifyResult.active(reason),
      'inactive' => PremiumVerifyResult.inactive(reason),
      'pending' => PremiumVerifyResult.pending(reason),
      'expired' => PremiumVerifyResult.expired(reason),
      'error' => PremiumVerifyResult.error(reason),
      'unverified' => PremiumVerifyResult.unverified(
          reason ?? 'provider_not_configured',
        ),
      _ => PremiumVerifyResult.unverified(reason ?? 'unknown_status'),
    };
  }
}
