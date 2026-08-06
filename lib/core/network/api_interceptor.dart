/// OR-1130 — Request/response interceptor contract.
library;

typedef InterceptorHandler = Future<Map<String, String>> Function(
  Map<String, String> headers,
);

abstract class ApiInterceptor {
  Future<Map<String, String>> onRequest(Map<String, String> headers);
  Future<void> onResponse(int statusCode, Map<String, String> headers);
  Future<void> onError(Object error);
}
