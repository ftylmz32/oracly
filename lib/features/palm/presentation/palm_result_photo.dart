/// Settled palm photo — elegant frame, no moving light, real evidence only.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/performance/oracly_decode_cache.dart';
import '../copy/palm_copy.dart';
import 'palm_photo_frame.dart';
import 'palm_photo_veil.dart';
import 'palm_tokens.dart';

class PalmResultPhoto extends StatefulWidget {
  const PalmResultPhoto({super.key, required this.path});

  final String path;

  @override
  State<PalmResultPhoto> createState() => _PalmResultPhotoState();
}

class _PalmResultPhotoState extends State<PalmResultPhoto> {
  double _aspect = 0.78;

  @override
  void initState() {
    super.initState();
    _resolveAspect(widget.path);
  }

  @override
  void didUpdateWidget(covariant PalmResultPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _resolveAspect(widget.path);
  }

  Future<void> _resolveAspect(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      // Tiny decode — aspect only; UI uses cacheWidth for display.
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final next = image.width / image.height;
      image.dispose();
      codec.dispose();
      if (!mounted) return;
      setState(() => _aspect = next.clamp(0.68, 1.05));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final side = PalmTokens.screenHorizontal;
    return Semantics(
      label: PalmCopy.previewLabel,
      image: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: side),
        child: PalmPhotoFrame(
          hero: true,
          child: AspectRatio(
            aspectRatio: _aspect,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(widget.path),
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, 0.06),
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                  cacheWidth: oraclyDecodeCachePx(720, dpr),
                  errorBuilder: (context, error, stack) => ColoredBox(
                    color: OraclyChrome.midnight,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: OraclyChrome.cream.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const IgnorePointer(child: PalmPhotoVeil()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
