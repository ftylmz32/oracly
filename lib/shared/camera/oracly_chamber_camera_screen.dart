/// Live chamber camera — framing guide over preview, soft shutter.
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

class OraclyChamberCameraScreen extends StatefulWidget {
  const OraclyChamberCameraScreen({super.key, required this.kind});

  final OraclyCaptureKind kind;

  @override
  State<OraclyChamberCameraScreen> createState() =>
      _OraclyChamberCameraScreenState();
}

class _OraclyChamberCameraScreenState extends State<OraclyChamberCameraScreen> {
  CameraController? _controller;
  String? _error;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _error = _unavailable);
        return;
      }
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        cam,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _error = _unavailable);
    }
  }

  String get _unavailable => widget.kind == OraclyCaptureKind.coffee
      ? CoffeeCopy.cameraUnavailable
      : PalmCopy.cameraUnavailable;

  String get _tip => widget.kind == OraclyCaptureKind.coffee
      ? CoffeeCopy.captureTips
      : PalmCopy.captureTips;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _shutter() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await c.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _unavailable;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller != null && _controller!.value.isInitialized;
    return Scaffold(
      backgroundColor: const Color(0xFF07040F),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              CameraPreview(_controller!)
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    _error ?? '…',
                    textAlign: TextAlign.center,
                    style: ReadingTypography.secondary(
                      color: OraclyA11y.creamSecondary(OraclyChrome.cream),
                    ),
                  ),
                ),
              ),
            if (ready)
              widget.kind == OraclyCaptureKind.coffee
                  ? CoffeeCupCaptureGuide(
                      tip: CoffeeCopy.captureGuide,
                      detail: CoffeeCopy.captureTips,
                    )
                  : PalmHandCaptureGuide(tip: _tip),
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
                enabled: ready && !_busy && _error == null,
                onPressed: _shutter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
