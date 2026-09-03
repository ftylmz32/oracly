/// Palm framing guide — elegant stage frame + concise copy. No hand art.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';
import 'palm_frame_painter.dart';

class PalmHandCaptureGuide extends StatelessWidget {
  const PalmHandCaptureGuide({
    super.key,
    this.tip,
    this.detail,
  });

  final String? tip;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: const PalmFramePainter(),
        child: _GuideCopy(tip: tip, detail: detail),
      ),
    );
  }
}

class _GuideCopy extends StatelessWidget {
  const _GuideCopy({this.tip, this.detail});

  final String? tip;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    if (tip == null && detail == null) return const SizedBox.expand();
    return Align(
      alignment: const Alignment(0, 0.78),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tip != null)
              Text(
                tip!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ReadingTypography.secondary(
                  color: OraclyChrome.cream.withValues(alpha: 0.90),
                ),
              ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ReadingTypography.footnote(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.78),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
