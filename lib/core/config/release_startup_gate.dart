/// Fail-closed startup decision for a misconfigured production release.
library;

import 'package:flutter/material.dart';

import 'oracly_runtime_config.dart';

enum ReleaseStartupDecision { allow, blockMisconfiguredRelease }

abstract final class ReleaseStartupGate {
  ReleaseStartupGate._();

  /// Only a release-locked PRODUCTION build is gated, on the existing
  /// [OraclyRuntimeConfig.missingMandatoryReleaseKeys] contract.
  /// Development (never release-locked), internal and staging keep their
  /// current behaviour.
  static ReleaseStartupDecision evaluate(OraclyRuntimeConfig config) {
    if (!config.releaseLocked || !config.environment.isProduction) {
      return ReleaseStartupDecision.allow;
    }
    return config.isReleaseConfigComplete
        ? ReleaseStartupDecision.allow
        : ReleaseStartupDecision.blockMisconfiguredRelease;
  }

  /// The root to run instead of the product, or null to start normally.
  static Widget? blockedRoot(OraclyRuntimeConfig config) =>
      evaluate(config) == ReleaseStartupDecision.blockMisconfiguredRelease
          ? const ReleaseConfigFailureApp()
          : null;
}

/// Terminal screen for a build shipped without its mandatory endpoints.
/// No providers, no retry (the values are fixed at build time), and never
/// any configuration value.
class ReleaseConfigFailureApp extends StatelessWidget {
  const ReleaseConfigFailureApp({super.key});

  static const message =
      'Bu sürüm doğru yapılandırılmadı. Lütfen uygulamayı güncelleyin.';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(message, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
