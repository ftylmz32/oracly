/// Live chamber camera — framing guide over preview, soft shutter.
library;

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../features/coffee/copy/coffee_copy.dart';
import '../../features/palm/copy/palm_copy.dart';
import 'oracly_capture_kind.dart';
import 'oracly_chamber_camera_body.dart';

class OraclyChamberCameraScreen extends StatefulWidget {
  const OraclyChamberCameraScreen({super.key, required this.kind});

  final OraclyCaptureKind kind;

  @override
  State<OraclyChamberCameraScreen> createState() =>
      _OraclyChamberCameraScreenState();
}

class _OraclyChamberCameraScreenState extends State<OraclyChamberCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  var _busy = false;
  var _bootGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_boot());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bootGeneration++;
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android often emits `inactive` during takePicture / permission sheets.
    // Releasing there disposed the controller mid-shutter and blocked result flow.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_busy) return;
      unawaited(_releaseCamera());
      return;
    }
    if (state == AppLifecycleState.resumed &&
        mounted &&
        _controller == null) {
      if (_error != null) {
        setState(() => _error = null);
      }
      unawaited(_boot());
    }
  }

  Future<void> _releaseCamera() async {
    if (_busy) return;
    final c = _controller;
    if (c == null) return;
    _bootGeneration++;
    _controller = null;
    if (mounted) setState(() {});
    try {
      await c.dispose();
    } catch (_) {}
  }

  Future<void> _boot() async {
    final gen = ++_bootGeneration;
    try {
      final cameras = await availableCameras();
      if (!mounted || gen != _bootGeneration) return;
      if (cameras.isEmpty) {
        setState(() => _error = _unavailable);
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
      if (!mounted || gen != _bootGeneration) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted && gen == _bootGeneration) {
        setState(() => _error = _unavailable);
      }
    }
  }

  String get _unavailable => widget.kind == OraclyCaptureKind.coffee
      ? CoffeeCopy.cameraUnavailable
      : PalmCopy.cameraUnavailable;

  Future<void> _shutter() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await c.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      final alive = _controller?.value.isInitialized == true;
      if (!alive) {
        // Lifecycle disposed mid-shutter — recover instead of permanent fail.
        setState(() => _error = null);
        unawaited(_boot());
        return;
      }
      setState(() => _error = _unavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OraclyChamberCameraBody(
      kind: widget.kind,
      controller: _controller,
      error: _error,
      busy: _busy,
      onShutter: _shutter,
    );
  }
}
