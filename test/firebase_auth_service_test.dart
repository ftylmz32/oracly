/// Firebase Auth adapter — Android config is native; tests stay mocked.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/auth_copy.dart';
import 'package:oracly_new/core/auth/auth_service_selection.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_gateway.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_service.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_user.dart';
import 'package:oracly_new/core/auth/firebase/firebase_id_token_manager.dart';
import 'package:oracly_new/core/auth/mock_auth_service.dart';
import 'package:oracly_new/core/auth/models/auth_credentials.dart';
import 'package:oracly_new/core/auth/session_manager.dart';
import 'package:oracly_new/core/auth/token_manager.dart';
import 'package:oracly_new/core/auth/unconfigured_auth_service.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/openai/openai_oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'support/test_app_check_token.dart';

const _idToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.e30.sig';
const _proxy = 'https://api.oracly.app/v1/ai/complete';

void main() {
  test('production without Firebase selects UnconfiguredAuth, not MockAuth', () {
    final auth = AuthServiceSelection.create(
      productionLike: true,
      firebaseReady: false,
    );
    expect(auth, isA<UnconfiguredAuthService>());
    expect(auth, isNot(isA<MockAuthService>()));
    expect(auth.isConfigured, isFalse);
  });

  test('missing Firebase production config fails clearly without mock tokens',
      () async {
    final tokens = _MemTokens();
    final auth = UnconfiguredAuthService(tokens: tokens);
    final result = await auth.signInAnonymously();
    expect(result.isFailure, isTrue);
    expect(result.errorOrNull?.message, AuthCopy.notConfigured);
    expect(tokens.access, isNull);
  });

  test('development without Firebase may use MockAuthService', () {
    final auth = AuthServiceSelection.create(
      productionLike: false,
      firebaseReady: false,
    );
    expect(auth, isA<MockAuthService>());
    expect(auth.isConfigured, isTrue);
  });

  test('Firebase ready selects FirebaseAuthService', () {
    final auth = AuthServiceSelection.create(
      productionLike: true,
      firebaseReady: true,
      gateway: FakeFirebaseAuthGateway(),
    );
    expect(auth, isA<FirebaseAuthService>());
    expect(auth.isConfigured, isTrue);
  });

  test('signed out / signed in / logout / token refresh', () async {
    final gateway = FakeFirebaseAuthGateway();
    final tokens = FirebaseIdTokenManager(gateway, fallback: _MemTokens());
    final sessions = InMemorySessionManager(tokens);
    final auth = FirebaseAuthService(
      gateway: gateway,
      tokens: tokens,
      sessions: sessions,
    );

    expect(await tokens.getAccessToken(), isNull);
    expect(sessions.currentSession, isNull);

    final signedIn = await auth.signInAnonymously();
    expect(signedIn.isSuccess, isTrue);
    expect(signedIn.dataOrNull?.userId, 'uid-1');
    expect(signedIn.dataOrNull?.accessToken, _idToken);
    expect(await tokens.getAccessToken(), _idToken);
    expect(sessions.currentSession?.userId, 'uid-1');

    gateway.forceRefreshSeen = false;
    final refreshed = await auth.refreshSession();
    expect(refreshed.isSuccess, isTrue);
    expect(gateway.forceRefreshSeen, isTrue);
    expect(await tokens.getAccessToken(forceRefresh: true), _idToken);

    await auth.signOut();
    expect(await tokens.getAccessToken(), isNull);
    expect(sessions.currentSession, isNull);
    auth.dispose();
  });

  test('email failure does not invent a token', () async {
    final gateway = FakeFirebaseAuthGateway()..failEmail = true;
    final auth = FirebaseAuthService(gateway: gateway);
    final result = await auth.signInWithEmail(
      const EmailCredentials(email: 'a@b.c', password: 'x'),
    );
    expect(result.isFailure, isTrue);
    expect(result.errorOrNull?.message, AuthCopy.invalidCredentials);
    expect(await gateway.currentIdToken(), isNull);
    auth.dispose();
  });

  test('ProxyAiTransport attaches Firebase ID token, not mock or sk-', () async {
    http.Request? seen;
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: _proxy,
    );
    final gateway = FakeFirebaseAuthGateway();
    await gateway.signInAnonymously();
    final tokens = FirebaseIdTokenManager(gateway);
    final ai = OpenAiOraclyAiService(
      config: config,
      transport: ProxyAiTransport(
        config: config,
      appCheckToken: testAppCheckToken,
        accessToken: tokens.getAccessToken,
        client: MockClient((request) async {
          seen = request;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'success': true,
                'data': {'text': 'Sakin bir nefes al ve bugunu yumusak tut.'},
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    final result = await ai.chat(userMessage: 'Merhaba, bugun nasilsin?');
    expect(result.isSuccess, isTrue, reason: '${result.failure}');
    expect(seen!.headers['Authorization'], 'Bearer $_idToken');
    expect(seen!.headers['Authorization'], isNot(contains('mock_')));
    expect(seen!.headers['Authorization'], isNot(contains('sk-')));
  });
}

class FakeFirebaseAuthGateway implements FirebaseAuthGateway {
  FakeFirebaseAuthGateway();

  final _controller = StreamController<FirebaseAuthUserSnapshot?>.broadcast();
  FirebaseAuthUserSnapshot? _user;
  bool forceRefreshSeen = false;
  bool failEmail = false;

  @override
  bool get isInitialized => true;

  @override
  FirebaseAuthUserSnapshot? get currentUser => _user;

  @override
  Stream<FirebaseAuthUserSnapshot?> authStateChanges() => _controller.stream;

  @override
  Future<String?> currentIdToken({bool forceRefresh = false}) async {
    if (forceRefresh) forceRefreshSeen = true;
    if (_user == null) return null;
    return _idToken;
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInAnonymously() async {
    _user = const FirebaseAuthUserSnapshot(uid: 'uid-1', isAnonymous: true);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (failEmail) {
      throw AuthGatewayException('invalid-credential', code: 'invalid-credential');
    }
    _user = FirebaseAuthUserSnapshot(uid: 'uid-mail', email: email);
    _controller.add(_user);
    return _user!;
  }

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
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}

class _MemTokens implements TokenManager {
  String? access;
  String? refresh;

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async => access;

  @override
  Future<String?> getRefreshToken() async => refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    access = null;
    refresh = null;
  }

  @override
  Future<bool> hasValidAccessToken() async =>
      access != null && access!.isNotEmpty;
}
