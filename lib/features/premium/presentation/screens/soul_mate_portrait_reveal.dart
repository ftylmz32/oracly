/// Cinematic portrait reveal — dark to soft light. No sparkle, no hearts.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/app_motion.dart';
import '../../../../core/performance/oracly_decode_cache.dart';
import '../../../../core/theme/oracly_quiet_motion.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/soul_mate_copy.dart';
import 'soul_mate_portrait_lightbox.dart';
import 'soul_mate_portrait_plate.dart';

class SoulMatePortraitReveal extends StatefulWidget {
  const SoulMatePortraitReveal({super.key, required this.imageBytes});

  final List<int> imageBytes;

  @override
  State<SoulMatePortraitReveal> createState() => _SoulMatePortraitRevealState();
}

class _SoulMatePortraitRevealState extends State<SoulMatePortraitReveal>
    with SingleTickerProviderStateMixin {
  late Uint8List _bytes;
  late final AnimationController _reveal;
  int? _cacheW;

  @override
  void initState() {
    super.initState();
    _bind(widget.imageBytes);
    _reveal = AnimationController(
      vsync: this,
      duration: AppMotionDuration.slow,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final logical = (MediaQuery.sizeOf(context).width - 20).clamp(120.0, 420.0);
    _cacheW = oraclyDecodeCachePx(logical, dpr);
    if (OraclyQuietMotion.still(context)) {
      _reveal.value = 1;
    } else if (!_reveal.isCompleted && !_reveal.isAnimating) {
      _reveal.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(SoulMatePortraitReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.imageBytes, widget.imageBytes)) {
      _bind(widget.imageBytes);
      if (!OraclyQuietMotion.still(context)) {
        _reveal.forward(from: 0);
      } else {
        _reveal.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _bind(List<int> raw) {
    _bytes = raw is Uint8List ? raw : Uint8List.fromList(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: SoulMateCopy.portraitSemantics,
      image: true,
      child: OraclyPressable(
        onTap: () => showSoulMatePortraitLightbox(
          context,
          imageBytes: widget.imageBytes,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: AppLayout.contentBottomBreath,
          ),
          child: AnimatedBuilder(
            animation: _reveal,
            builder: (context, _) => SoulMatePortraitPlate(
              bytes: _bytes,
              progress: _reveal.value,
              cacheWidth: _cacheW,
            ),
          ),
        ),
      ),
    );
  }
}
