/// Proxy AI authorization preflight - shared path for non-Tarot features.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_bootstrap.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_gateway.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_user.dart';
import 'package:oracly_new/core/auth/mock_auth_service.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_proxy_readiness.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/transport/ai_operation.dart';
import 'package:oracly_new/features/ai/production/transport/ai_proxy_request.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport_selection.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_headers.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';

import 'support/test_app_check_token.dart';

const _proxy = 'https://api.oracly.app/v1/ai/complete';
const _prod = AiRuntimeConfig(
  environment: AppEnvironment.production,
  proxyUrl: _proxy,
);
const _dev = AiRuntimeConfig(
  environment: AppEnvironment.development,
  proxyUrl: _proxy,
);

void main() {
  setUp(FirebaseAuthBootstrap.reset);
  tearDown(FirebaseAuthBootstrap.reset);

  test('authenticated Firebase user passes preflight', () async {
    FirebaseAuthBootstrap.debugSetReady(true);
    final failure = await AiProxyReadiness.ensure(
      config: _prod,
      accessToken: ({bool forceRefresh = false}) async => 'firebase-id',
      appCheckToken: testAppCheckToken,
      liveGateway: _FakeGateway.signedIn(),
    );
    expect(failure, isNull);
  });

  test('valid token sends HTTP request with Bearer header', () async {
    FirebaseAuthBootstrap.debugSetReady(true);
    http.Request? seen;
    final outcome = await ProxyAiTransport(
      config: _prod,
      accessToken: ({bool forceRefresh = false}) async => 'firebase-id',
      appCheckToken: testAppCheckToken,
      liveGateway: _FakeGateway.signedIn(),
      client: MockClient((request) async {
        seen = request;
        return http.Response(
          '{"success":true,"data":{"text":"ok"}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    ).execute(_req(AiOperation.palmAnalysis));
    expect(outcome.isSuccess, isTrue, reason: '${outcome.failure}');
    expect(seen, isNotNull);
    expect(seen!.headers['Authorization'], 'Bearer firebase-id');
  });

  test('auth bootstrap pending is not permanent unauthorized', () async {
    FirebaseAuthBootstrap.reset();
    final failure = await AiProxyReadiness.ensure(
      config: _prod,
      accessToken: ({bool forceRefresh = false}) async => null,
      appCheckToken: testAppCheckToken,
    );
    expect(failure?.kind, AiFailureKind.authPending);
    expect(failure?.kind, isNot(AiFailureKind.unauthorized));
  });

  test('missing user after bootstrap is typed unauthorized', () async {
    FirebaseAuthBootstrap.debugSetReady(true);
    final gateway = _FakeGateway()..refuseSignIn = true;
    final failure = await AiProxyReadiness.ensure(
      config: _prod,
      auth: MockAuthService(),
      accessToken: ({bool forceRefresh = false}) async => null,
      appCheckToken: testAppCheckToken,
      liveGateway: gateway,
    );
    expect(failure?.kind, AiFailureKind.unauthorized);
  });

  test('token acquisition failure is retryable authPending', () async {
    FirebaseAuthBootstrap.debugSetReady(true);
    final failure = await AiProxyReadiness.ensure(
      config: _prod,
      accessToken: ({bool forceRefresh = false}) async => null,
      appCheckToken: testAppCheckToken,
      liveGateway: _FakeGateway.signedIn()..tokenBroken = true,
    );
    expect(failure?.kind, AiFailureKind.authPending);
  });

  test('App Check failure is distinguishable from unauthorized', () async {
    FirebaseAuthBootstrap.debugSetReady(true);
    final failure = await AiProxyReadiness.ensure(
      config: _prod,
      accessToken: ({bool forceRefresh = false}) async => 'firebase-id',
      appCheckToken: ({bool forceRefresh = false}) async => null,
      liveGateway: _FakeGateway.signedIn(),
    );
    expect(failure?.kind, AiFailureKind.appCheck);
    expect(failure?.kind, isNot(AiFailureKind.unauthorized));
  });

  test('Coffee Palm Dream OR SoulMate share corrected proxy path', () async {
    FirebaseAuthBootstrap.debugSetReady(true);
    final ops = [
      AiOperation.coffeeAnalysis,
      AiOperation.palmAnalysis,
      AiOperation.dreamAnalysis,
      AiOperation.chat,
      AiOperation.soulmateDraw,
    ];
    for (final op in ops) {
      var sent = false;
      final transport = AiTransportSelection.create(
        _prod,
        accessToken: ({bool forceRefresh = false}) async => 'firebase-id',
        appCheckToken: testAppCheckToken,
        liveGateway: _FakeGateway.signedIn(),
        client: MockClient((request) async {
          sent = true;
          expect(request.headers['Authorization'], 'Bearer firebase-id');
          return http.Response(
            '{"success":true,"data":{"text":"ok"}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      expect(transport, isA<ProxyAiTransport>());
      final outcome = await transport!.execute(_req(op));
      expect(outcome.isSuccess, isTrue, reason: '$op ${outcome.failure}');
      expect(sent, isTrue, reason: '$op');
    }
  });

  test('live gateway signs in when access token is missing', () async {
    FirebaseAuthBootstrap.debugSetReady(true);
    final gateway = _FakeGateway();
    final failure = await AiProxyReadiness.ensure(
      config: _prod,
      accessToken: ({bool forceRefresh = false}) async => null,
      appCheckToken: testAppCheckToken,
      liveGateway: gateway,
    );
    expect(failure, isNull);
    expect(gateway.currentUser, isNotNull);
  });

  test('production does not send mock or OpenAI keys', () {
    expect(ProxyAiHeaders.maySendUserToken(_prod, 'mock_abc'), isFalse);
    expect(ProxyAiHeaders.maySendUserToken(_prod, 'sk-secret'), isFalse);
    expect(ProxyAiHeaders.maySendUserToken(_prod, 'firebase-id'), isTrue);
    expect(ProxyAiHeaders.maySendUserToken(_dev, 'mock_abc'), isTrue);
  });
}

AiProxyRequest _req(AiOperation operation) => AiProxyRequest(
      operation: operation,
      model: 'gpt-4o',
      payload: const {'userMessage': 'Merhaba'},
    );

class _FakeGateway implements FirebaseAuthGateway {
  _FakeGateway();

  factory _FakeGateway.signedIn() {
    final g = _FakeGateway();
    g._user = const FirebaseAuthUserSnapshot(uid: 'uid-1', isAnonymous: true);
    return g;
  }

  FirebaseAuthUserSnapshot? _user;
  bool refuseSignIn = false;
  bool tokenBroken = false;

  @override
  bool get isInitialized => true;

  @override
  FirebaseAuthUserSnapshot? get currentUser => _user;

  @override
  Stream<FirebaseAuthUserSnapshot?> authStateChanges() =>
      const Stream<FirebaseAuthUserSnapshot?>.empty();

  @override
  Future<String?> currentIdToken({bool forceRefresh = false}) async {
    if (tokenBroken || _user == null) return null;
    return 'live-firebase-id';
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInAnonymously() async {
    if (refuseSignIn) {
      throw AuthGatewayException('anonymous-failed', code: 'internal');
    }
    _user = const FirebaseAuthUserSnapshot(uid: 'uid-1', isAnonymous: true);
    return _user!;
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInWithEmail({
    required String email,
    required String password,
  }) =>
      signInAnonymously();

  @override
  Future<FirebaseAuthUserSnapshot> signInWithGoogle({
    required String idToken,
    String? accessToken,
  }) =>
      signInAnonymously();

  @override
  Future<FirebaseAuthUserSnapshot> signInWithApple({required String idToken}) =>
      signInAnonymously();

  @override
  Future<void> signOut() async => _user = null;

  @override
  Future<void> deleteCurrentUser() async => _user = null;
}
