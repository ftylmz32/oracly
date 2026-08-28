/// OR-1130 — Injects bearer tokens into outgoing requests.
library;

import '../auth/token_manager.dart';
import 'api_interceptor.dart';

class AuthInterceptor implements ApiInterceptor {
  AuthInterceptor(this._tokenManager);

  final TokenManager _tokenManager;

  @override
  Future<Map<String, String>> onRequest(Map<String, String> headers) async {
    final token = (await _tokenManager.getAccessToken())?.trim();
    if (token == null || token.isEmpty) return headers;
    if (token.startsWith('sk-')) return headers;
    headers = Map<String, String>.from(headers)
      ..['Authorization'] = 'Bearer $token';
    return headers;
  }

  @override
  Future<void> onResponse(int statusCode, Map<String, String> headers) async {}

  @override
  Future<void> onError(Object error) async {}
}
