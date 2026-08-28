/// Analyzing-phase canvas — real photo with cosmetic scan only.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/performance/oracly_decode_cache.dart';
import 'palm_analysis_fx.dart';
import 'palm_photo_frame.dart';
import 'palm_photo_veil.dart';
import 'palm_tokens.dart';

class PalmAnalysisCanvas extends StatefulWidget {
  const PalmAnalysisCanvas({
    super.key,
    required this.path,
    this.contain = true,
  });

  final String path;
  final bool contain;

  @override
  State<PalmAnalysisCanvas> createState() => _PalmAnalysisCanvasState();
}

class _PalmAnalysisCanvasState extends State<PalmAnalysisCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  double _settle = 0;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _clock.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) _clock.stop();
    });
    _clock.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _settle = 1);
    });
  }

  @override
  void didUpdateWidget(covariant PalmAnalysisCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _clock
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return PalmPhotoFrame(
      hero: false,
      child: ColoredBox(
        color: PalmTokens.veilInk,
        child: AnimatedOpacity(
          opacity: _settle,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(widget.path),
                fit: widget.contain ? BoxFit.contain : BoxFit.cover,
                alignment: Alignment.center,
                gaplessPlayback: true,
                filterQuality: FilterQuality.high,
                cacheWidth: oraclyDecodeCachePx(560, dpr),
                errorBuilder: (context, error, stack) => Icon(
                  Icons.front_hand_outlined,
                  color: OraclyChrome.goldLight.withValues(alpha: 0.42),
                  size: 48,
                ),
              ),
              const IgnorePointer(child: PalmPhotoVeil()),
              AnimatedBuilder(
                animation: _clock,
                builder: (context, _) =>
                    PalmAnalysisFxLayer(t: _clock.value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
