from pathlib import Path

base = Path(r"c:\Dev\oracly_new\lib\features\palm\presentation")

def w(name, content):
    p = base / name
    p.write_text(content, encoding="utf-8", newline="\n")
    print(f"{len(content.splitlines()):3} {name}")

w("palm_hero.dart", r'''/// El Falı hero — photoreal hand on velvet. Silhouette only as fallback.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/oracly_quiet_motion.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../copy/palm_copy.dart';
import 'palm_hero_field.dart';
import 'palm_photo_frame.dart';
import 'palm_photo_veil.dart';
import 'palm_silhouette_art.dart';

class PalmHero extends StatefulWidget {
  const PalmHero({super.key, this.height});

  final double? height;

  @override
  State<PalmHero> createState() => _PalmHeroState();
}

class _PalmHeroState extends State<PalmHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7200),
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
        final h = widget.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 220.0);
        final w =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        return Semantics(
          label: PalmCopy.screenTitle,
          child: SizedBox(
            height: h,
            width: w,
            child: AnimatedBuilder(
              animation: _breath,
              child: RepaintBoundary(
                child: PalmPhotoFrame(
                  hero: true,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Transform.scale(
                        scale: 1.02,
                        alignment: const Alignment(0.04, -0.06),
                        child: OraclyAssetImage(
                          assetPath: AppAssets.palmRitualHero,
                          width: w,
                          height: h,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0.06, 0.04),
                          filterQuality: FilterQuality.high,
                          fallback: ColoredBox(
                            color: OraclyChrome.midnight,
                            child: Center(
                              child: PalmSilhouetteArt(
                                size: (h * 0.72).clamp(100.0, 220.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const IgnorePointer(child: PalmPhotoVeil()),
                    ],
                  ),
                ),
              ),
              builder: (context, child) {
                final t =
                    OraclyQuietMotion.still(context) ? 0.14 : _breath.value;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    PalmHeroField(size: math.max(w, h), phase: t),
                    child!,
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
''')

w("palm_result_photo.dart", r'''/// Settled palm photo — elegant frame, no moving light, real evidence only.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/performance/oracly_decode_cache.dart';
import '../copy/palm_copy.dart';
import 'palm_photo_frame.dart';
import 'palm_photo_veil.dart';
import 'palm_tokens.dart';

class PalmResultPhoto extends StatefulWidget {
  const PalmResultPhoto({super.key, required this.path});

  final String path;

  @override
  State<PalmResultPhoto> createState() => _PalmResultPhotoState();
}

class _PalmResultPhotoState extends State<PalmResultPhoto> {
  double _aspect = 0.78;

  @override
  void initState() {
    super.initState();
    _resolveAspect(widget.path);
  }

  @override
  void didUpdateWidget(covariant PalmResultPhoto oldWidget) {
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
      setState(() => _aspect = next.clamp(0.68, 1.05));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final side = PalmTokens.screenHorizontal;
    return Semantics(
      label: PalmCopy.previewLabel,
      image: true,
      child: Transform.translate(
        offset: Offset(-side * 0.35, 0),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width - side * 1.3,
          child: PalmPhotoFrame(
            hero: true,
            child: AspectRatio(
              aspectRatio: _aspect,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(widget.path),
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, 0.06),
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
                  const IgnorePointer(child: PalmPhotoVeil()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
''')

w("palm_hand_wait.dart", r'''/// Wait over the real palm photo — line-light, never a fake scan HUD.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import 'palm_atmosphere_light.dart';
import 'palm_gold_preview.dart';

class PalmHandWait extends StatelessWidget {
  const PalmHandWait({
    super.key,
    required this.message,
    required this.path,
    this.subtitle,
  });

  final String message;
  final String path;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    // Parent screen already applies side padding — avoid double inset.
    return Column(
      children: [
        Expanded(
          child: PalmGoldPreview(
            path: path,
            contain: true,
            soft: true,
            overlay: const PalmAtmosphereLight(),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: ReadingTypography.opening(
            color: OraclyChrome.cream.withValues(alpha: 0.92),
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: ReadingTypography.footnote(
              color: OraclyChrome.cream.withValues(alpha: 0.72),
            ),
          ),
        ],
        SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
''')

w("palm_loading_view.dart", r'''/// Palm analysis wait — real hand when present, never a Material spinner.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../copy/palm_copy.dart';
import 'palm_atmosphere_light.dart';
import 'palm_hand_wait.dart';
import 'palm_photo_frame.dart';

class PalmLoadingView extends StatelessWidget {
  const PalmLoadingView({
    super.key,
    required this.message,
    this.subtitle,
    this.imagePath,
  });

  final String message;
  final String? subtitle;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path != null && File(path).existsSync()) {
      return PalmHandWait(
        message: message,
        subtitle: subtitle,
        path: path,
      );
    }
    return _QuietWait(message: message, subtitle: subtitle);
  }
}

class _QuietWait extends StatelessWidget {
  const _QuietWait({required this.message, this.subtitle});

  final String message;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 220,
          child: PalmPhotoFrame(
            hero: true,
            child: Stack(
              fit: StackFit.expand,
              children: [
                OraclyAssetImage(
                  assetPath: AppAssets.palmRitualHero,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  fallback: ColoredBox(
                    color: OraclyChrome.midnight,
                    child: Icon(
                      Icons.front_hand_outlined,
                      color: OraclyChrome.goldLight.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                const PalmAtmosphereLight(),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          message,
          textAlign: TextAlign.center,
          style: ReadingTypography.opening(
            color: OraclyChrome.cream.withValues(alpha: 0.92),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          subtitle ?? PalmCopy.analyzingHint,
          textAlign: TextAlign.center,
          style: ReadingTypography.footnote(
            color: OraclyChrome.cream.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}
''')

w("palm_result_view.dart", r'''/// The user's hand settles, then one spoken reading follows.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/oracly_soft_reveal.dart';
import '../../../core/reading_ux/reading_long_form_scroll.dart';
import '../../../core/reading_version/services/reading_version_payload.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../copy/palm_copy.dart';
import '../models/palm_reading.dart';
import 'palm_result_actions.dart';
import 'palm_result_photo.dart';
import 'palm_result_sections.dart';

class PalmResultView extends ConsumerStatefulWidget {
  const PalmResultView({
    super.key,
    required this.reading,
    required this.onNewPalm,
    this.onReinterpret,
    this.versionReloadToken = 0,
  });

  final PalmReading reading;
  final VoidCallback onNewPalm;
  final Future<bool> Function()? onReinterpret;
  final int versionReloadToken;

  @override
  ConsumerState<PalmResultView> createState() => _PalmResultViewState();
}

class _PalmResultViewState extends ConsumerState<PalmResultView> {
  late PalmReading _display;

  @override
  void initState() {
    super.initState();
    _display = widget.reading;
  }

  @override
  void didUpdateWidget(covariant PalmResultView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reading.id != widget.reading.id ||
        oldWidget.versionReloadToken != widget.versionReloadToken) {
      _display = widget.reading;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reading = _display;
    final path = reading.imagePath;
    return ReadingLongFormScroll(
      kicker: PalmCopy.overallTitle,
      // Parent chamber already applies side padding.
      padding: EdgeInsets.zero,
      children: [
        if (path != null && File(path).existsSync()) ...[
          SizedBox(height: CraftsmanshipRhythm.afterTitle),
          PalmResultPhoto(path: path),
          SizedBox(height: CraftsmanshipRhythm.betweenActs * 0.45),
        ],
        OraclySoftReveal(
          delay: const Duration(milliseconds: 240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PalmResultSections(reading: reading),
              PalmResultActions(
                reading: reading,
                onNewPalm: widget.onNewPalm,
                versionReloadToken: widget.versionReloadToken,
                onReinterpret: widget.onReinterpret,
                onVersionSelect: (group) {
                  final entry = group.activeEntry;
                  if (entry == null) return;
                  setState(() {
                    _display = ReadingVersionPayload.applyPalm(
                      widget.reading,
                      entry.data,
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
''')

print("hero/result/wait/loading done")
