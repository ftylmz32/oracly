import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/oracly_app.dart';
import 'app/providers/app_providers.dart';
import 'core/auth/account_deletion_owner_bootstrap.dart';
import 'core/auth/account_deletion_pending_state.dart';
import 'core/auth/firebase/firebase_app_check_bootstrap.dart';
import 'core/auth/firebase/firebase_auth_bootstrap.dart';
import 'core/config/app_config.dart';
import 'core/data/datasources/local_storage.dart';
import 'core/l10n/oracly_format.dart';
import 'core/platform/oracly_phone_orientation.dart';
import 'core/telemetry/crash_telemetry_bootstrap.dart';
import 'features/privacy/providers/privacy_control_providers.dart';
import 'features/share_reopen/services/share_link_inbox.dart';
import 'screens/splash/splash_startup_log.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await OraclyPhoneOrientation.lockPhonesToPortrait();
    SplashStartupLog.mark('MAIN_START');
    AccountDeletionPendingState.beginStartup();

    ShareLinkInbox.instance.capture(
      WidgetsBinding.instance.platformDispatcher.defaultRouteName,
    );

    if (!kReleaseMode) {
      try {
        await dotenv.load(fileName: '.env.example', isOptional: true);
      } catch (_) {}
    }

    final storage = LocalStorage.ephemeral();
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
      ],
    );

    SplashStartupLog.mark('RUNAPP');
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const OraclyApp(),
      ),
    );

    unawaited(_deferredStartup(container, storage));
  }, CrashTelemetryBootstrap.recordZoneError);
}

Future<void> _deferredStartup(
  ProviderContainer container,
  LocalStorage storage,
) async {
  try {
    await OraclyFormat.ensureInitialized();
  } catch (_) {}
  try {
    await AppConfig.initialize();
  } catch (_) {}

  // Durable storage first, then routing-critical deletion gate — BEFORE any
  // owner-bound cache hydration (Premium, push, anonymous owner bootstrap).
  try {
    await storage.tryPromote();
  } catch (_) {}
  try {
    await AccountDeletionPendingState.resolveFromLocalStorage(storage);
  } catch (_) {
    AccountDeletionPendingState.markStorageUnavailable();
  }

  await FirebaseAuthBootstrap.tryInitialize();
  await FirebaseAppCheckBootstrap.tryActivate();
  container.invalidate(firebaseAuthReadyProvider);

  await AccountDeletionPendingState.resolveAndReconcile(
    storage,
    container.read(accountDeletionServiceProvider),
  );

  if (!AccountDeletionPendingState.allowsOwnerBoundExperience) {
    await CrashTelemetryBootstrap.install(container);
    return;
  }

  await AccountDeletionOwnerBootstrap.runIfClear(container);
  await CrashTelemetryBootstrap.install(container);
}
