/// Real palm photo surface — same frame language as hero and result.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/performance/oracly_decode_cache.dart';
import 'palm_photo_frame.dart';
import 'palm_photo_veil.dart';
import 'palm_tokens.dart';

class PalmGoldPreview extends StatelessWidget {
  const PalmGoldPreview({
    super.key,
    required this.path,
    this.contain = false,
    this.soft = false,
    this.overlay,
  });

  final String path;
  final bool contain;
  final bool soft;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return PalmPhotoFrame(
      hero: !soft,
      child: ColoredBox(
        color: PalmTokens.veilInk,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(path),
              fit: contain ? BoxFit.contain : BoxFit.cover,
              alignment: Alignment.center,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
              cacheWidth: oraclyDecodeCachePx(soft ? 560 : 720, dpr),
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.front_hand_outlined,
                  color: OraclyChrome.goldLight.withValues(alpha: 0.42),
                  size: 48,
                );
              },
            ),
            const IgnorePointer(child: PalmPhotoVeil()),
            ?overlay,
          ],
        ),
      ),
    );
  }
}
