/// Optional low-opacity edge sketch on result photo — cosmetic blend only.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/palm_edge_sketch.dart';

class PalmResultSketchLayer extends StatefulWidget {
  const PalmResultSketchLayer({super.key, required this.path});

  final String path;

  @override
  State<PalmResultSketchLayer> createState() => _PalmResultSketchLayerState();
}

class _PalmResultSketchLayerState extends State<PalmResultSketchLayer> {
  Uint8List? _sketch;

  @override
  void initState() {
    super.initState();
    _load(widget.path);
  }

  @override
  void didUpdateWidget(covariant PalmResultSketchLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _sketch = null;
      _load(widget.path);
    }
  }

  Future<void> _load(String path) async {
    final bytes = await PalmEdgeSketch.fromPath(path);
    if (!mounted || path != widget.path) return;
    setState(() => _sketch = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _sketch;
    if (bytes == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: Opacity(
        opacity: 0.28,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          alignment: const Alignment(0, 0.06),
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
          colorBlendMode: BlendMode.screen,
        ),
      ),
    );
  }
}
