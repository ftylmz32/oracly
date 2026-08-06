/// OR-1130 — Typed API response envelope.
library;

class ApiResponse<T> {
  const ApiResponse({
    required this.statusCode,
    required this.data,
    this.headers = const {},
    this.message,
  });

  final int statusCode;
  final T? data;
  final Map<String, String> headers;
  final String? message;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  ApiResponse<R> map<R>(R Function(T? data) transform) {
    return ApiResponse<R>(
      statusCode: statusCode,
      data: transform(data),
      headers: headers,
      message: message,
    );
  }
}
