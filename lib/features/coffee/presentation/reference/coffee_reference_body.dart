/// Phase body for Kahve Falı reference screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../personal_discovery/models/personal_discovery_profile.dart';
import '../../../personal_discovery/providers/personal_discovery_providers.dart';
import '../../controllers/coffee_reading_controller.dart';
import '../../copy/coffee_copy.dart';
import '../../services/coffee_fortune_composer.dart';
import 'coffee_capture_view.dart';
import 'coffee_error_view.dart';
import 'coffee_landing_view.dart';
import 'coffee_loading_view.dart';
import 'coffee_result_view.dart';

class CoffeeReferenceBody extends ConsumerWidget {
  const CoffeeReferenceBody({
    super.key,
    required this.controller,
    required this.onAnalyze,
    required this.onHistory,
    this.busy = false,
  });

  final CoffeeReadingController controller;
  final VoidCallback onAnalyze;
  final VoidCallback onHistory;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final landing = CoffeeLandingView(
      cameraEnabled: controller.images.cameraAvailable,
      hasHistory: controller.history.isNotEmpty,
      onCamera: () {
        // Chamber capture lives on CoffeeCaptureView — avoid OS picker dual path.
        controller.startCapture();
      },
      onGallery: () async {
        controller.startCapture();
        await controller.pickGallery();
      },
      onHistory: onHistory,
    );
    return switch (controller.phase) {
      CoffeePhase.entry => landing,
      CoffeePhase.capture => CoffeeCaptureView(
          controller: controller,
          busy: busy,
          onAnalyze: onAnalyze,
        ),
      CoffeePhase.analyzing => CoffeeLoadingView(
          message: CoffeeCopy.analyzing,
          subtitle: CoffeeCopy.analyzingSubtitle,
          imagePath: controller.image?.path,
        ),
      CoffeePhase.result when controller.reading != null => CoffeeResultView(
          reading: CoffeeFortuneComposer.compose(
            controller.reading!,
            themes: _themes(
              ref.watch(personalDiscoveryProfileProvider).asData?.value,
            ),
          ),
          onNewCup: controller.backToEntry,
          onReinterpret: controller.image == null
              ? null
              : () async {
                  await controller.reinterpret();
                  return controller.lastVersionAdded;
                },
          versionReloadToken: controller.versionReloadToken,
        ),
      // Never fall through to landing with a silent empty result.
      CoffeePhase.result => CoffeeErrorView(
          message: CoffeeCopy.analysisFailed,
          onRetry: controller.image != null ? onAnalyze : controller.retryCapture,
          onBack: controller.backToEntry,
        ),
      CoffeePhase.error => CoffeeErrorView(
          message: controller.errorMessage ?? CoffeeCopy.analysisFailed,
          onRetry: controller.image != null
              ? onAnalyze
              : controller.retryCapture,
          onBack: controller.backToEntry,
        ),
    };
  }
}

List<String> _themes(PersonalDiscoveryProfile? profile) {
  if (profile == null) return const [];
  final seen = <String>{};
  final out = <String>[];
  void add(String raw) {
    final text = raw.trim();
    if (text.isEmpty || !seen.add(text.toLowerCase())) return;
    out.add(text);
  }

  for (final theme in profile.recurringThemes) {
    add(theme);
  }
  for (final signal in profile.themeSignals) {
    if (signal.isRecurring) add(signal.label);
  }
  return out;
}
