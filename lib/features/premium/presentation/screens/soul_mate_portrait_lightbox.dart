/// Full-screen portrait view — tap hero to enlarge.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/performance/oracly_decode_cache.dart';
import '../../../../core/theme/app_colors.dart';
import '../../copy/soul_mate_copy.dart';

Future<void> showSoulMatePortraitLightbox(
  BuildContext context, {
  required List<int> imageBytes,
}) {
  final bytes = imageBytes is Uint8List
      ? imageBytes
      : Uint8List.fromList(imageBytes);
  final cacheW = oraclyDecodeCachePx(
    MediaQuery.sizeOf(context).width,
    MediaQuery.devicePixelRatioOf(context),
  );
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.88),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Semantics(
        label: SoulMateCopy.portraitSemantics,
        image: true,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: OraclyChrome.heroRadius,
              border: Border.all(
                color: OraclyChrome.gold.withValues(alpha: 0.45),
              ),
            ),
            child: ClipRRect(
              borderRadius: OraclyChrome.heroRadius,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 3,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  cacheWidth: cacheW,
                  errorBuilder: (_, e, s) => ColoredBox(
                    color: AppColors.surface,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: OraclyChrome.gold.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
