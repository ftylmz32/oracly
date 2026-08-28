from pathlib import Path

base = Path(r"c:\Dev\oracly_new\lib\features\palm\presentation")

def w(name, content):
    p = base / name
    p.write_text(content, encoding="utf-8", newline="\n")
    print(f"{len(content.splitlines()):3} {name}")

w("palm_photo_frame.dart", r'''/// Shared gold frame for palm photos — landing, capture, wait, result.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import 'palm_tokens.dart';

class PalmPhotoFrame extends StatelessWidget {
  const PalmPhotoFrame({
    super.key,
    required this.child,
    this.hero = false,
    this.attention = false,
  });

  final Widget child;
  final bool hero;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final goldA = attention ? 0.40 : (hero ? 0.30 : 0.26);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: PalmTokens.heroRadius,
        boxShadow: PalmTokens.frameShadows(hero: hero),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: PalmTokens.heroRadius,
          border: Border.all(
            color: OraclyChrome.gold.withValues(alpha: goldA),
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: PalmTokens.heroRadius,
          child: child,
        ),
      ),
    );
  }
}
''')

w("palm_photo_veil.dart", r'''/// Settled vignette over palm photos — shared depth, never analysis motion.
library;

import 'package:flutter/material.dart';

import 'palm_tokens.dart';

class PalmPhotoVeil extends StatelessWidget {
  const PalmPhotoVeil({super.key});

  @override
  Widget build(BuildContext context) {
    final ink = PalmTokens.veilInk;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.06, -0.08),
          radius: 1.12,
          colors: [
            Colors.transparent,
            ink.withValues(alpha: 0.18),
          ],
          stops: const [0.55, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ink.withValues(alpha: 0.06),
              Colors.transparent,
              ink.withValues(alpha: 0.26),
            ],
            stops: const [0, 0.48, 1],
          ),
        ),
      ),
    );
  }
}
''')

w("palm_gold_preview.dart", r'''/// Real palm photo surface — same frame language as hero and result.
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
            if (overlay != null) overlay!,
          ],
        ),
      ),
    );
  }
}
''')

print("frame/veil/preview ok")
