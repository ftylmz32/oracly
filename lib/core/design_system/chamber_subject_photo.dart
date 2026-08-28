/// The subject's own surface — large, quiet, never a gold postcard.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../performance/oracly_decode_cache.dart';
import '../theme/app_colors.dart';

class ChamberSubjectPhoto extends StatelessWidget {
  const ChamberSubjectPhoto({
    super.key,
    required this.path,
    required this.label,
  });

  final String path;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Semantics(
      label: label,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 0.92,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(path),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                cacheWidth: oraclyDecodeCachePx(420, dpr),
                errorBuilder: (context, error, stack) => ColoredBox(
                  color: AppColors.surface,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textHint,
                  ),
                ),
              ),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66080512),
                        Color(0x00000000),
                        Color(0xCC080512),
                      ],
                      stops: [0, 0.45, 1],
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
