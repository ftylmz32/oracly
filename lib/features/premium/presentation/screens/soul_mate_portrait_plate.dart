/// Portrait plate — face kept in frame; soft cinematic veil only.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_colors.dart';

class SoulMatePortraitPlate extends StatelessWidget {
  const SoulMatePortraitPlate({
    super.key,
    required this.bytes,
    required this.progress,
    this.cacheWidth,
  });

  final Uint8List bytes;
  final double progress;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final curve = Curves.easeOutCubic.transform(t);
    final light = Curves.easeInOut.transform((t * 1.08).clamp(0.0, 1.0));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: OraclyChrome.heroRadius,
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: 0.16 + curve * 0.16),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: OraclyChrome.violet.withValues(alpha: 0.08 + light * 0.08),
            blurRadius: 16 + light * 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: OraclyChrome.heroRadius,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF080512)),
              Opacity(
                opacity: curve,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.18),
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                  cacheWidth: cacheWidth,
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: AppColors.surface.withValues(alpha: 0.8),
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: OraclyChrome.gold.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      radius: 1.1,
                      colors: [
                        Color.fromRGBO(255, 220, 180, 0.10 * light),
                        Color.fromRGBO(8, 5, 18, 0.55 * (1 - light * 0.65)),
                      ],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(8, 5, 18, 0.35 * (1 - curve)),
                        Colors.transparent,
                        const Color.fromRGBO(8, 5, 18, 0.42),
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
