/// HTTP client for POST /v1/review-access/activate — never invents [granted].
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/review_access_result.dart';

abstract class ReviewAccessService {
  bool get isConfigured;
  Future<ReviewAccessResult> activate(String code);
}

class HttpReviewAccessService implements ReviewAccessService {
  HttpReviewAccessService({
    required this.activateUrl,
    this.accessTokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String? activateUrl;
  final Future<String?> Function()? accessTokenProvider;
  final http.Client _client;

  @override
  bool get isConfigured => (activateUrl ?? '').trim().isNotEmpty;

  @override
  Future<ReviewAccessResult> activate(String code) async {
    final url = activateUrl;
    if (url == null || url.isEmpty) {
      // Genuinely not configured on this build — a real, definitive answer.
      return ReviewAccessResult.denied('not_configured');
    }
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      return ReviewAccessResult.denied('invalid_request', definitive: false);
    }
    try {
      final headers = <String, String>{'content-type': 'application/json'};
      final token = (await accessTokenProvider?.call())?.trim();
      if (token != null && token.isNotEmpty && !token.startsWith('sk-')) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await _client
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode({'code': trimmed}),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        // Could be a stale/expired Firebase token on a cold start, not
        // necessarily an invalid reviewer code — not definitive.
        return ReviewAccessResult.denied('auth_required', definitive: false);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Server/network-layer failure (5xx, rate limit, etc.) — not the
        // server telling us the code is wrong.
        return ReviewAccessResult.denied(
          'http_${response.statusCode}',
          definitive: false,
        );
      }
      final body = jsonDecode(response.body);
      if (body is! Map) {
        return ReviewAccessResult.denied('invalid_response', definitive: false);
      }
      final granted = body['granted'] == true;
      if (granted) return ReviewAccessResult.granted();
      // A well-formed 2xx JSON answer with granted:false is the real
      // server verdict (wrong code, or the code was disabled/reconfigured).
      return ReviewAccessResult.denied(
        (body['reason'] as String?) ?? 'invalid_code',
      );
    } catch (_) {
      return ReviewAccessResult.denied('network_or_parse', definitive: false);
    }
  }
}
