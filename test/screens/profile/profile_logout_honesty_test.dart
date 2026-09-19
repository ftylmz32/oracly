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
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/screens/profile/copy/profile_copy.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_screen.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    OraclyL10n.bind('tr');
    PathProviderPlatform.instance = _LogoutPathProvider();
  });

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
    await tester.pump(const Duration(milliseconds: 1200));

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
    await tester.pump(const Duration(milliseconds: 1200));

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
    await tester.pump(const Duration(milliseconds: 2000));
    expect(auth.signOutCalls, 2);
    expect(find.text(AuthCopy.signedOut), findsOneWidget);
  });

  testWidgets(
    'R2.1 — sign-out requests server-side push-token unregister while the old identity is still authenticated, before completing sign-out',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final calls = <String>[];
      final auth = _ControllableAuth()..order = calls;
      final sessions = InMemorySessionManager(_MemTokens());
      await sessions.setSession(_session());
      final sender = _RecordingSender(calls);
      await _pump(
        tester,
        storage: storage,
        auth: auth,
        sessions: sessions,
        sender: sender.call,
      );

      await tester.ensureVisible(find.text(ProfileCopy.logoutTitle));
      await tester.tap(find.text(ProfileCopy.logoutTitle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      expect(sender.calls, hasLength(1));
      expect(sender.calls.single.method, 'POST');
      expect(
        sender.calls.single.path,
        '/v1/reading-notifications/token/unregister',
      );
      // The cleanup call is awaited strictly before signOut() runs.
      expect(calls, ['unregister', 'sign_out']);
      expect(auth.signOutCalls, 1);
      expect(find.text(AuthCopy.signedOut), findsOneWidget);
    },
  );

  testWidgets(
    'R2.1 — a push-cleanup network failure never blocks sign-out',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final auth = _ControllableAuth();
      final sessions = InMemorySessionManager(_MemTokens());
      await sessions.setSession(_session());
      final sender = _ThrowingSender();
      await _pump(
        tester,
        storage: storage,
        auth: auth,
        sessions: sessions,
        sender: sender.call,
      );

      await tester.ensureVisible(find.text(ProfileCopy.logoutTitle));
      await tester.tap(find.text(ProfileCopy.logoutTitle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      expect(sender.callCount, 1);
      expect(auth.signOutCalls, 1);
      expect(find.text(AuthCopy.signedOut), findsOneWidget);
      expect(find.text(AuthCopy.signOutFailed), findsNothing);
    },
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required LocalStorage storage,
  required AuthService auth,
  required SessionManager sessions,
  ReadingOperationSender? sender,
}) async {
  await tester.binding.setSurfaceSize(const Size(360, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
        authServiceProvider.overrideWithValue(auth),
        sessionManagerProvider.overrideWithValue(sessions),
        if (sender != null)
          readingOperationSenderProvider.overrideWithValue(sender),
      ],
      child: const MaterialApp(home: ProfileReferenceScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _RecordedCall {
  const _RecordedCall(this.method, this.path, this.body);
  final String method;
  final String path;
  final Map<String, Object>? body;
}

class _RecordingSender {
  _RecordingSender(this._order);
  final List<String> _order;
  final List<_RecordedCall> calls = [];

  Future<ReadingOperationWire?> call(
    String method,
    String path,
    Map<String, Object>? body,
  ) async {
    calls.add(_RecordedCall(method, path, body));
    _order.add('unregister');
    return const ReadingOperationWire(statusCode: 200, json: {'data': {}});
  }
}

class _ThrowingSender {
  int callCount = 0;

  Future<ReadingOperationWire?> call(
    String method,
    String path,
    Map<String, Object>? body,
  ) async {
    callCount++;
    throw Exception('simulated push-cleanup network failure');
  }
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
  List<String>? order;

  @override
  bool get isConfigured => true;

  @override
  Future<ApiResult<bool>> signOut() async {
    signOutCalls++;
    order?.add('sign_out');
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
  bool get isCurrentUserAnonymous => true;

  @override
  Future<ApiResult<bool>> reauthenticate(
    AccountReauthCredentials credentials,
  ) async {
    throw UnsupportedError('reauth is not part of this logout test');
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

class _LogoutPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async => '.';

  @override
  Future<String?> getApplicationDocumentsPath() async => '.';

  @override
  Future<String?> getTemporaryPath() async => '.';

  @override
  Future<String?> getApplicationCachePath() async => '.';
}
