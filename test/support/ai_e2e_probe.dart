import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/openai/openai_oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';
import '../support/test_app_check_token.dart';

const e2eProxyUrl = 'http://127.0.0.1:8787/v1/ai/complete';
const e2eAuthProxyUrl = 'http://127.0.0.1:8788/v1/ai/complete';
const e2eDeadProxyUrl = 'http://127.0.0.1:8799/v1/ai/complete';

const e2eProviderSkip =
    'Backend has no OpenAI key configured. Set OPENAI_API_KEY in '
    'backend/.env manually - the agent will not copy or read it.';

String? e2eProviderBlocker;
bool _providerChecked = false;
Future<void>? _liveProxyChain;

bool e2eIsDevLiveProxy(Uri url) =>
    url.host == '127.0.0.1' && url.port == 8787;

/// Serialize live-proxy HTTP across E2E tests — in-process + cross-isolate.
/// Prevents accidental rate-limit races without changing production code.
Future<T> e2eSerializedLiveProxy<T>(Future<T> Function() body) async {
  final previous = _liveProxyChain;
  final done = Completer<void>();
  _liveProxyChain = done.future;
  if (previous != null) await previous;
  final lockFile = File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}'
    'oracly_e2e_live_proxy.lock',
  );
  RandomAccessFile? raf;
  try {
    raf = await lockFile.open(mode: FileMode.write);
    for (;;) {
      try {
        await raf.lock(FileLock.exclusive);
        break;
      } on PathAccessException {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
    }
    return await body();
  } finally {
    try {
      await raf?.unlock();
    } catch (_) {}
    await raf?.close();
    done.complete();
  }
}

Future<void> detectE2eProvider() async {
  if (_providerChecked) return;
  _providerChecked = true;
  final probe = AiE2eProbe();
  final result = await e2eLiveAi(probe).chat(
    userMessage: 'Merhaba, bugun sakin bir nefes almak istiyorum.',
  );
  if (result.failure?.kind == AiFailureKind.noConfiguration) {
    e2eProviderBlocker = e2eProviderSkip;
  }
}

/// True when the local Fastify proxy has a working provider key.
bool get e2eProviderConfigured =>
    _providerChecked && e2eProviderBlocker == null;

void e2eFailIfRateLimited(AiFailureKind? kind, [String? message]) {
  if (kind == AiFailureKind.rateLimit) {
    throw StateError(
      'Live proxy rate-limited (not a product defect): ${message ?? kind}',
    );
  }
}

class AiE2eProbe extends http.BaseClient {
  AiE2eProbe([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final requests = <http.Request>[];

  http.Request get last => requests.last;
  Uri get lastUrl => last.url;
  String? get lastBody => last.body;
  List<String> get bodies => [for (final r in requests) r.body];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request is http.Request) requests.add(request);
    if (e2eIsDevLiveProxy(request.url)) {
      return e2eSerializedLiveProxy(() => _inner.send(request));
    }
    return _inner.send(request);
  }
}

class _SerialHttp extends http.BaseClient {
  _SerialHttp([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (e2eIsDevLiveProxy(request.url)) {
      return e2eSerializedLiveProxy(() => _inner.send(request));
    }
    return _inner.send(request);
  }
}

OpenAiOraclyAiService e2eLiveAi(AiE2eProbe probe) {
  const config = AiRuntimeConfig(proxyUrl: e2eProxyUrl, model: 'gpt-4o-mini');
  return OpenAiOraclyAiService(
    config: config,
    transport: ProxyAiTransport(
      config: config,
      appCheckToken: testAppCheckToken,
      accessToken: testAccessToken,
      client: probe,
    ),
  );
}

OpenAiOraclyAiService e2eAi(
  String url, {
  Future<String?> Function({bool forceRefresh})? token,
}) {
  final config = AiRuntimeConfig(proxyUrl: url);
  return OpenAiOraclyAiService(
    config: config,
    transport: ProxyAiTransport(
      config: config,
      appCheckToken: testAppCheckToken,
      accessToken: token ?? testAccessToken,
      client: _SerialHttp(),
    ),
  );
}

void assertProxyOnly(AiE2eProbe probe, {required String forbidden}) {
  if (probe.requests.isEmpty) {
    throw StateError('no proxy request captured');
  }
  if (probe.lastUrl.toString() != e2eProxyUrl) {
    throw StateError('expected $e2eProxyUrl got ${probe.lastUrl}');
  }
  if (probe.lastUrl.host == 'api.openai.com') {
    throw StateError('Flutter called OpenAI directly');
  }
  final auth = probe.last.headers['authorization'];
  if (auth != null) {
    throw StateError('unexpected Authorization: $auth');
  }
  final body = probe.lastBody ?? '';
  if (body.contains(forbidden) || body.contains('sk-')) {
    throw StateError('secret leaked into proxy body');
  }
}

void assertCleanError(String message) {
  final lower = message.toLowerCase();
  for (final needle in ['fastify', 'openai', 'econnrefused', 'stack', 'sk-']) {
    if (lower.contains(needle)) {
      throw StateError('raw backend detail in UI copy: $message');
    }
  }
}
