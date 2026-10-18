/// Premium palm framing stage — capture guidance only.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/oracly_quiet_motion.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../models/palm_hand.dart';
import 'palm_capture_palm_guide_painter.dart';

class PalmCapturePalmGuide extends StatefulWidget {
  const PalmCapturePalmGuide({super.key, required this.hand});

  final PalmHand hand;

  @override
  State<PalmCapturePalmGuide> createState() => _PalmCapturePalmGuideState();
}

class _PalmCapturePalmGuideState extends State<PalmCapturePalmGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, rest: 0.14);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = (w * 0.95).clamp(240.0, 320.0);
        return Semantics(
          image: true,
          label: widget.hand.label,
          child: SizedBox(
            width: w,
            height: h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AnimatedBuilder(
                animation: _breath,
                builder: (context, _) {
                  final pulse = OraclyQuietMotion.still(context)
                      ? 0.14
                      : 0.5 + math.sin(_breath.value * math.pi * 2) * 0.5;
                  // home_palm.webp is a right palm (thumb on the image's
                  // right, wrist at the bottom); only the left guide mirrors.
                  final mirror = widget.hand == PalmHand.left;
                  return RepaintBoundary(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: const Color(0xFF050308),
                          child: Transform(
                            key: ValueKey(
                              'palm-capture-guide-${widget.hand.name}',
                            ),
                            alignment: Alignment.center,
                            transform: Matrix4.diagonal3Values(
                              mirror ? -1 : 1,
                              1,
                              1,
                            ),
                            child: const OraclyAssetImage(
                              assetPath: AppAssets.homePalm,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: CustomPaint(
                            painter: PalmCapturePalmGuidePainter(pulse: pulse),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
