/// P1 — Profile notifications and logout stay honest.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/auth_copy.dart';
import 'package:oracly_new/core/auth/auth_service.dart';
import 'package:oracly_new/core/auth/mock_auth_service.dart';
import 'package:oracly_new/core/auth/models/auth_credentials.dart';
import 'package:oracly_new/core/auth/models/auth_session.dart';
import 'package:oracly_new/core/auth/session_manager.dart';
import 'package:oracly_new/core/auth/token_manager.dart';
import 'package:oracly_new/core/auth/unconfigured_auth_service.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/network/api_result.dart';
import 'package:oracly_new/screens/profile/copy/profile_copy.dart';
import 'package:oracly_new/screens/profile/reference/profile_account_session.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_screen.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
  });

  test('logout only for a real non-mock account session', () {
    final mock = MockAuthService();
    final unconfigured = UnconfiguredAuthService();
    expect(profileHasRealAccountSession(auth: mock, session: null), isFalse);
    expect(
      profileHasRealAccountSession(auth: unconfigured, session: null),
      isFalse,
    );
    expect(
      profileHasRealAccountSession(
        auth: mock,
        session: _session(token: 'mock_access_1'),
      ),
      isFalse,
    );
    expect(
      profileHasRealAccountSession(
        auth: _RecordingAuth(),
        session: _session(guest: true, provider: AuthProviderKind.guest),
      ),
      isFalse,
    );
    expect(
      profileHasRealAccountSession(
        auth: _RecordingAuth(),
        session: _session(provider: AuthProviderKind.anonymous),
      ),
      isFalse,
    );
    expect(
      profileHasRealAccountSession(auth: _RecordingAuth(), session: _session()),
      isTrue,
    );
  });

  testWidgets('Bildirimler is not a Profile shortcut; Ayarlar is real', (
    tester,
  ) async {
    await _pumpProfile(tester, storage: storage);
    expect(find.text(ProfileCopy.notificationsTitle), findsNothing);
    expect(find.text(ProfileCopy.orTitle), findsOneWidget);
    await tester.ensureVisible(find.text(ProfileCopy.settingsTitle));
    await tester.tap(find.text(ProfileCopy.settingsTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SettingsReferenceScreen), findsOneWidget);
    expect(find.text(ProfileCopy.notificationsUnavailable), findsNothing);
  });

  testWidgets('Çıkış signs out a real authenticated session', (tester) async {
    final auth = _RecordingAuth();
    final sessions = InMemorySessionManager(_MemTokens());
    await sessions.setSession(_session());
    await _pumpProfile(
      tester,
      storage: storage,
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        sessionManagerProvider.overrideWithValue(sessions),
      ],
    );

    expect(find.text(ProfileCopy.logoutTitle), findsOneWidget);
    await tester.ensureVisible(find.text(ProfileCopy.logoutTitle));
    await tester.pump();
    await tester.tap(find.text(ProfileCopy.logoutTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(auth.signOutCalls, 1);
    expect(find.text(AuthCopy.signedOut), findsOneWidget);
  });
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  required LocalStorage storage,
  List<Override> overrides = const [],
}) async {
  // Tall enough for the full settings list without flaky scroll hit-tests.
  await tester.binding.setSurfaceSize(const Size(360, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        ...overrides,
      ],
      child: const MaterialApp(home: ProfileReferenceScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

AuthSession _session({
  String token = 'firebase_id_token_live',
  bool guest = false,
  AuthProviderKind provider = AuthProviderKind.email,
}) {
  return AuthSession(
    userId: 'uid-live',
    provider: provider,
    accessToken: token,
    refreshToken: 'refresh',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    isGuest: guest,
  );
}

class _RecordingAuth implements AuthService {
  int signOutCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<ApiResult<bool>> signOut() async {
    signOutCalls++;
    return const ApiSuccess(true);
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
    throw UnsupportedError('sign-in is not part of this Profile test');
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
