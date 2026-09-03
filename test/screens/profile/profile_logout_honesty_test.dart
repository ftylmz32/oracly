/// Logout reports success only when sign-out succeeds.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/auth_copy.dart';
import 'package:oracly_new/core/auth/auth_service.dart';
import 'package:oracly_new/core/auth/models/auth_credentials.dart';
import 'package:oracly_new/core/auth/models/auth_session.dart';
import 'package:oracly_new/core/auth/session_manager.dart';
import 'package:oracly_new/core/auth/token_manager.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/network/api_result.dart';
import 'package:oracly_new/core/network/network_exception.dart';
import 'package:oracly_new/screens/profile/copy/profile_copy.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  testWidgets('successful logout shows signed-out message once', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final auth = _ControllableAuth();
    final sessions = InMemorySessionManager(_MemTokens());
    await sessions.setSession(_session());
    await _pump(tester, storage: storage, auth: auth, sessions: sessions);

    await tester.ensureVisible(find.text(ProfileCopy.logoutTitle));
    await tester.tap(find.text(ProfileCopy.logoutTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(auth.signOutCalls, 1);
    expect(find.text(AuthCopy.signedOut), findsOneWidget);
    expect(find.text(AuthCopy.signOutFailed), findsNothing);
  });

  testWidgets('failed logout shows error and does not claim success', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final auth = _ControllableAuth()..fail = true;
    final sessions = InMemorySessionManager(_MemTokens());
    await sessions.setSession(_session());
    await _pump(tester, storage: storage, auth: auth, sessions: sessions);

    await tester.ensureVisible(find.text(ProfileCopy.logoutTitle));
    await tester.tap(find.text(ProfileCopy.logoutTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(auth.signOutCalls, 1);
    expect(find.text(AuthCopy.signOutFailed), findsOneWidget);
    expect(find.text(AuthCopy.signedOut), findsNothing);
    expect(find.text(ProfileCopy.logoutTitle), findsOneWidget);
  });

  testWidgets('duplicate logout taps while in flight are ignored', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final auth = _ControllableAuth()..delay = const Duration(milliseconds: 400);
    final sessions = InMemorySessionManager(_MemTokens());
    await sessions.setSession(_session());
    await _pump(tester, storage: storage, auth: auth, sessions: sessions);

    await tester.ensureVisible(find.text(ProfileCopy.logoutTitle));
    await tester.tap(find.text(ProfileCopy.logoutTitle));
    await tester.pump(const Duration(milliseconds: 20));
    // In-flight logout hides the CTA so a second tap cannot re-enter.
    expect(find.text(ProfileCopy.logoutTitle), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));

    expect(auth.signOutCalls, 1);
    expect(find.text(AuthCopy.signedOut), findsOneWidget);
  });

  testWidgets('retry after failure can succeed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final auth = _ControllableAuth()..fail = true;
    final sessions = InMemorySessionManager(_MemTokens());
    await sessions.setSession(_session());
    await _pump(tester, storage: storage, auth: auth, sessions: sessions);

    await tester.ensureVisible(find.text(ProfileCopy.logoutTitle));
    await tester.tap(find.text(ProfileCopy.logoutTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(AuthCopy.signOutFailed), findsOneWidget);

    auth.fail = false;
    await tester.tap(find.text(ProfileCopy.logoutTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(auth.signOutCalls, 2);
    expect(find.text(AuthCopy.signedOut), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required LocalStorage storage,
  required AuthService auth,
  required SessionManager sessions,
}) async {
  await tester.binding.setSurfaceSize(const Size(360, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        authServiceProvider.overrideWithValue(auth),
        sessionManagerProvider.overrideWithValue(sessions),
      ],
      child: const MaterialApp(home: ProfileReferenceScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

AuthSession _session() => AuthSession(
  userId: 'uid-live',
  provider: AuthProviderKind.email,
  accessToken: 'firebase_id_token_live',
  refreshToken: 'refresh',
  expiresAt: DateTime.now().add(const Duration(hours: 1)),
  isGuest: false,
);

class _ControllableAuth implements AuthService {
  int signOutCalls = 0;
  bool fail = false;
  Duration delay = Duration.zero;

  @override
  bool get isConfigured => true;

  @override
  Future<ApiResult<bool>> signOut() async {
    signOutCalls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (fail) {
      return const ApiFailure(NetworkException(message: 'provider'));
    }
    return const ApiSuccess(true);
  }

  @override
  Future<ApiResult<bool>> deleteAccount() async {
    throw UnsupportedError('delete is not part of this logout test');
  }

  @override
  Future<ApiResult<AuthSession>> signInAnonymously() => _unused();

  @override
  Future<ApiResult<AuthSession>> createGuestSession() => _unused();

  @override
  Future<ApiResult<AuthSession>> refreshSession() => _unused();

  @override
  Future<ApiResult<AuthSession>> ensureAnonymousSession() => _unused();

  @override
  Future<ApiResult<AuthSession>> signInWithApple(OAuthCredentials c) =>
      _unused();

  @override
  Future<ApiResult<AuthSession>> signInWithEmail(EmailCredentials c) =>
      _unused();

  @override
  Future<ApiResult<AuthSession>> signInWithGoogle(OAuthCredentials c) =>
      _unused();

  Future<ApiResult<AuthSession>> _unused() {
    throw UnsupportedError('sign-in is not part of this logout test');
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
