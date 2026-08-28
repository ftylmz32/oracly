import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/anonymous_auth_bootstrap.dart';
import 'package:oracly_new/core/auth/auth_service.dart';
import 'package:oracly_new/core/auth/models/auth_credentials.dart';
import 'package:oracly_new/core/auth/models/auth_session.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/core/network/api_result.dart';
import 'package:oracly_new/features/gems/data/paid_ai_operation_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('cold start route recovery', () {
    test('unknown and reserved routes recover to a live route', () {
      for (final name in [
        '/this-route-does-not-exist',
        OraclyRoutes.numerology,
        OraclyRoutes.moonCalendar,
        OraclyRoutes.manifestation,
        OraclyRoutes.dailyEnergy,
      ]) {
        final route = OraclyRouteGenerator.onGenerateRoute(
          RouteSettings(name: name),
        );
        expect(route, isNotNull, reason: name);
      }
    });

    test('generator never returns null for arbitrary deep links', () {
      final route = OraclyRouteGenerator.onGenerateRoute(
        const RouteSettings(name: '/garbage%20link'),
      );
      expect(route, isNotNull);
    });
  });

  group('session storage recovery', () {
    test('ephemeral LocalStorage survives without SharedPreferences', () async {
      final storage = LocalStorage.ephemeral();
      expect(storage.isEphemeral, isTrue);
      await storage.setBool('onboarding_completed', true);
      expect(storage.getBool('onboarding_completed'), isTrue);
    });

    test('paid op store skips corrupt rows instead of aborting', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      const emptyId =
          '{"id":"","feature":"tarot","ledgerKey":"k","reason":"r","cost":1,"status":"providerOk","createdAtMs":1}';
      const good =
          '{"id":"ok-1","feature":"tarot","ledgerKey":"k","reason":"r","cost":20,"status":"providerOk","createdAtMs":2}';
      await storage.setStringList(PaidAiOperationStore.key, [
        'not-json',
        emptyId,
        good,
      ]);
      final store = PaidAiOperationStore(storage);
      final all = store.all();
      expect(all.length, 1);
      expect(all.first.id, 'ok-1');
      expect(store.needingSettle().single.id, 'ok-1');
    });
  });

  group('auth bootstrap fail-open', () {
    test('hanging ensureAnonymousSession times out without throwing', () async {
      final auth = _HangingAuth();
      final sw = Stopwatch()..start();
      final result = await AnonymousAuthBootstrap.ensure(
        auth,
        timeout: const Duration(milliseconds: 40),
      );
      sw.stop();
      expect(result, isNull);
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });
  });
}

class _HangingAuth implements AuthService {
  @override
  bool get isConfigured => true;

  @override
  Future<ApiResult<AuthSession>> ensureAnonymousSession() =>
      Completer<ApiResult<AuthSession>>().future;

  @override
  Future<ApiResult<AuthSession>> createGuestSession() =>
      ensureAnonymousSession();

  @override
  Future<ApiResult<AuthSession>> signInAnonymously() =>
      ensureAnonymousSession();

  @override
  Future<ApiResult<AuthSession>> signInWithEmail(EmailCredentials c) =>
      ensureAnonymousSession();

  @override
  Future<ApiResult<AuthSession>> signInWithGoogle(OAuthCredentials c) =>
      ensureAnonymousSession();

  @override
  Future<ApiResult<AuthSession>> signInWithApple(OAuthCredentials c) =>
      ensureAnonymousSession();

  @override
  Future<ApiResult<AuthSession>> refreshSession() => ensureAnonymousSession();

  @override
  Future<ApiResult<bool>> signOut() async => const ApiSuccess(true);
}
