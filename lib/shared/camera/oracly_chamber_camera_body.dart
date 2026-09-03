/// Chamber preview stack — guide, close, shutter.
library;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/accessibility/oracly_a11y.dart';
import '../../core/design_system/oracly_chrome.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/reading_typography.dart';
import '../../features/coffee/copy/coffee_copy.dart';
import '../../features/palm/copy/palm_copy.dart';
import 'guides/coffee_cup_capture_guide.dart';
import 'guides/palm_hand_capture_guide.dart';
import 'oracly_capture_kind.dart';
import 'oracly_chamber_shutter_button.dart';

class OraclyChamberCameraBody extends StatelessWidget {
  const OraclyChamberCameraBody({
    super.key,
    required this.kind,
    required this.controller,
    required this.error,
    required this.busy,
    required this.onShutter,
  });

  final OraclyCaptureKind kind;
  final CameraController? controller;
  final String? error;
  final bool busy;
  final VoidCallback onShutter;

  @override
  Widget build(BuildContext context) {
    final ready = controller != null && controller!.value.isInitialized;
    return Scaffold(
      backgroundColor: const Color(0xFF07040F),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              CameraPreview(controller!)
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    error ?? '…',
                    textAlign: TextAlign.center,
                    style: ReadingTypography.secondary(
                      color: OraclyA11y.creamSecondary(OraclyChrome.cream),
                    ),
                  ),
                ),
              ),
            if (ready)
              kind == OraclyCaptureKind.coffee
                  ? CoffeeCupCaptureGuide(
                      tip: CoffeeCopy.captureGuide,
                      detail: CoffeeCopy.captureTips,
                    )
                  : PalmHandCaptureGuide(
                      tip: PalmCopy.captureGuide,
                      detail: PalmCopy.captureTips,
                    ),
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                tooltip: OraclyL10n.t('a11y.close'),
                constraints: const BoxConstraints(
                  minWidth: OraclyA11y.minTouchTarget,
                  minHeight: OraclyA11y.minTouchTarget,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(
                  Icons.close_rounded,
                  color: OraclyA11y.creamSecondary(OraclyChrome.cream),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.92),
              child: OraclyChamberShutterButton(
                enabled: ready && !busy && error == null,
                onPressed: onShutter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
