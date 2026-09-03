/// Phase body for El Falı.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../../personal_discovery/providers/personal_discovery_providers.dart';
import '../controllers/palm_reading_controller.dart';
import '../copy/palm_copy.dart';
import '../services/palm_fortune_composer.dart';
import 'palm_capture_view.dart';
import 'palm_error_view.dart';
import 'palm_landing_view.dart';
import 'palm_loading_view.dart';
import 'palm_result_view.dart';

class PalmReferenceBody extends ConsumerWidget {
  const PalmReferenceBody({
    super.key,
    required this.controller,
    required this.onAnalyze,
    this.busy = false,
  });

  final PalmReadingController controller;
  final VoidCallback onAnalyze;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final landing = PalmLandingView(
      hand: controller.hand,
      onHand: controller.selectHand,
      analysisAvailable: controller.analysisAvailable,
      cameraEnabled: controller.images.cameraAvailable,
      onCamera: () {
        // Chamber capture lives on PalmCaptureView — avoid OS picker dual path.
        controller.startCapture();
      },
      onGallery: () async {
        controller.startCapture();
        await controller.pickGallery();
      },
    );
    return switch (controller.phase) {
      PalmPhase.entry => landing,
      PalmPhase.capture => PalmCaptureView(
          controller: controller,
          busy: busy,
          onAnalyze: onAnalyze,
        ),
      PalmPhase.analyzing => PalmLoadingView(
          message: PalmCopy.analyzing,
          subtitle: PalmCopy.analyzingHint,
          imagePath: controller.image?.path,
        ),
      PalmPhase.result when controller.reading != null => PalmResultView(
          reading: PalmFortuneComposer.compose(
            controller.reading!,
            themes: _themes(
              ref.watch(personalDiscoveryProfileProvider).asData?.value,
            ),
          ),
          onNewPalm: controller.backToEntry,
          onReinterpret: controller.image == null
              ? null
              : () async {
                  await controller.reinterpret();
                  return controller.lastVersionAdded;
                },
          versionReloadToken: controller.versionReloadToken,
        ),
      // Never fall through to landing with a silent empty result.
      PalmPhase.result => PalmErrorView(
          message: PalmCopy.analysisFailed,
          canRetrySameImage: controller.image != null,
          onRetry: controller.image != null ? onAnalyze : controller.retryCapture,
          onBack: controller.backToEntry,
        ),
      PalmPhase.error => PalmErrorView(
          message: controller.errorMessage ?? PalmCopy.analysisFailed,
          canRetrySameImage: controller.lastError?.canRetrySameImage == true &&
              controller.image != null,
          onRetry: () {
            final retrySame =
                controller.lastError?.canRetrySameImage == true &&
                    controller.image != null;
            if (retrySame) {
              onAnalyze();
            } else {
              controller.retryCapture();
            }
          },
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
