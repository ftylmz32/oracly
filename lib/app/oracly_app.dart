/// OR-1100 — Root application widget with Riverpod.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/data/datasources/local_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/navigation/oracly_route_generator.dart';
import '../screens/splash/splash_screen.dart';
import 'providers/app_providers.dart';

class OraclyApp extends ConsumerWidget {
  const OraclyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oracly',
      theme: AppTheme.dark,
      onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.35,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}

/// Bootstraps [LocalStorage] and [AppConfig] before the widget tree mounts.
Future<ProviderContainer> bootstrapProviders() async {
  await AppConfig.initialize();
  final storage = await LocalStorage.open();
  return ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
    ],
  );
}
