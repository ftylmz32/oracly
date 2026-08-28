/// Installs global Flutter/Dart error handlers for crash telemetry.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../reading/ai_output_quality_logger.dart';
import 'crash_telemetry_service.dart';

abstract final class CrashTelemetryBootstrap {
  CrashTelemetryBootstrap._();

  static CrashTelemetryService? _service;
  static bool _installed = false;

  static Future<void> install(ProviderContainer container) async {
    if (_installed) return;
    _installed = true;
    final service = container.read(crashTelemetryProvider);
    _service = service;

    AiOutputQualityLogger.bindSevereSink(
      ({required operation, required errorCategory}) {
        service.recordSevere(
          operation: operation,
          errorCategory: errorCategory,
        );
      },
    );

    final priorFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      priorFlutter?.call(details);
      _service?.recordError(
        details.exception,
        details.stack ?? StackTrace.current,
        fatal: true,
        operation: 'flutter_framework',
      );
    };

    final priorPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _service?.recordError(
        error,
        stack,
        fatal: true,
        operation: 'platform_dispatcher',
      );
      return priorPlatform?.call(error, stack) ?? false;
    };

    // Sink + queue flush must not block first frame / splash cinema.
    unawaited(service.initialize());
  }

  static void recordZoneError(Object error, StackTrace stack) {
    _service?.recordError(
      error,
      stack,
      fatal: true,
      operation: 'zone_uncaught',
    );
  }
}
