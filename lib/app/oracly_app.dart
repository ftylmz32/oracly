/// OR-1100 — Root application widget with Riverpod.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessibility/oracly_a11y.dart';
import '../core/auth/account_switch_refresh_host.dart';
import '../core/auth/anonymous_auth_bootstrap.dart';
import '../core/auth/firebase/firebase_app_check_bootstrap.dart';
import '../core/auth/firebase/firebase_auth_bootstrap.dart';
import '../core/config/app_config.dart';
import '../core/data/datasources/local_storage.dart';
import '../core/l10n/l10n.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/navigation/oracly_navigator_key.dart';
import '../core/navigation/oracly_page_transitions.dart';
import '../core/navigation/oracly_route_generator.dart';
import '../features/share_reopen/widgets/share_link_host.dart';
import '../screens/splash/splash_screen.dart';
import '../shared/navigation/oracly_navigation.dart';
import 'providers/app_providers.dart';

class OraclyApp extends ConsumerWidget {
  const OraclyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    OraclyL10n.bind(locale.languageCode);
    final themeMode = ref.watch(appThemeModeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: oraclyNavigatorKey,
      title: 'Oracly',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocale.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
      onUnknownRoute: (_) => OraclyPageTransitions.fade(
        page: const OraclyAppShell(),
      ),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final isLight = Theme.of(context).brightness == Brightness.light;
        return OraclyLocaleScope(
          code: locale.languageCode,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: (isLight
                    ? SystemUiOverlayStyle.dark
                    : SystemUiOverlayStyle.light)
                .copyWith(
              statusBarColor: AppColors.transparent,
              statusBarIconBrightness:
                  isLight ? Brightness.dark : Brightness.light,
              statusBarBrightness:
                  isLight ? Brightness.light : Brightness.dark,
            ),
            child: AccountSwitchRefreshHost(
              child: ShareLinkHost(
                child: MediaQuery(
                  data: media.copyWith(
                    textScaler: OraclyA11y.clampAppTextScaler(media.textScaler),
                  ),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}

/// Bootstraps [LocalStorage] and [AppConfig] before the widget tree mounts.
/// Never blocks first paint on network auth — anonymous ensure runs in parallel.
Future<ProviderContainer> bootstrapProviders() async {
  await AppConfig.initialize();
  await FirebaseAuthBootstrap.tryInitialize();
  await FirebaseAppCheckBootstrap.tryActivate();
  final storage = await LocalStorage.open();
  final container = ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
    ],
  );
  unawaited(
    AnonymousAuthBootstrap.ensure(container.read(authServiceProvider)),
  );
  return container;
}
