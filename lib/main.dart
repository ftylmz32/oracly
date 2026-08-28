import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/oracly_app.dart';
import 'app/providers/app_providers.dart';
import 'core/auth/anonymous_auth_bootstrap.dart';
import 'core/auth/firebase/firebase_app_check_bootstrap.dart';
import 'core/auth/firebase/firebase_auth_bootstrap.dart';
import 'core/config/app_config.dart';
import 'core/data/datasources/local_storage.dart';
import 'core/l10n/oracly_format.dart';
import 'core/telemetry/crash_telemetry_bootstrap.dart';
import 'features/share_reopen/services/share_link_inbox.dart';
import 'screens/splash/splash_startup_log.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SplashStartupLog.mark('MAIN_START');

    // Capture route name without blocking first frame.
    ShareLinkInbox.instance.capture(
      WidgetsBinding.instance.platformDispatcher.defaultRouteName,
    );

    // Ephemeral storage → first Flutter frame paints brand overlay immediately.
    // Heavy init continues in parallel (see _deferredStartup).
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
  if (!kReleaseMode) {
    try {
      await dotenv.load(fileName: '.env.example', isOptional: true);
    } catch (_) {}
  }
  try {
    await AppConfig.initialize();
  } catch (_) {}
  try {
    await storage.tryPromote();
  } catch (_) {}
  await FirebaseAuthBootstrap.tryInitialize();
  await FirebaseAppCheckBootstrap.tryActivate();
  unawaited(
    AnonymousAuthBootstrap.ensure(container.read(authServiceProvider)),
  );
  await CrashTelemetryBootstrap.install(container);
}