/// Cinematic hero — the user's REAL cup. Never generic art. Never fake marks.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/performance/oracly_decode_cache.dart';
import '../../copy/coffee_copy.dart';
import 'coffee_cup_frame.dart';
import 'coffee_result_markers.dart';
import 'coffee_result_photo_veil.dart';

class CoffeeResultPhoto extends StatefulWidget {
  const CoffeeResultPhoto({
    super.key,
    required this.path,
    this.marks = const [],
    this.onMarkTap,
  });

  final String path;
  final List<CoffeeGroundedMark> marks;
  final ValueChanged<CoffeeGroundedMark>? onMarkTap;

  @override
  State<CoffeeResultPhoto> createState() => _CoffeeResultPhotoState();
}

class _CoffeeResultPhotoState extends State<CoffeeResultPhoto> {
  double _aspect = 0.82;

  @override
  void initState() {
    super.initState();
    _resolveAspect(widget.path);
  }

  @override
  void didUpdateWidget(covariant CoffeeResultPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _resolveAspect(widget.path);
  }

  Future<void> _resolveAspect(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final next = image.width / image.height;
      image.dispose();
      if (!mounted) return;
      setState(() => _aspect = next.clamp(0.68, 1.15));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Semantics(
      label: CoffeeCopy.previewLabel,
      image: true,
      child: CoffeeCupFrame(
        hero: true,
        child: AspectRatio(
          aspectRatio: _aspect,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(widget.path),
                fit: BoxFit.fill,
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
              const IgnorePointer(child: CoffeeResultPhotoVeil()),
              if (widget.marks.isNotEmpty)
                CoffeeResultMarkerLayer(
                  marks: widget.marks,
                  onTap: widget.onMarkTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
