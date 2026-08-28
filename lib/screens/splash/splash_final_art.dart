/// The single final splash raster — BoxFit.cover, emblem+wordmark safe.
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import 'splash_destination.dart';

class SplashFinalArt extends StatelessWidget {
  const SplashFinalArt({
    super.key,
    this.onPainted,
    this.onFailed,
  });

  /// Fires once when the final raster has a decoded frame to paint.
  final VoidCallback? onPainted;

  /// Fires once if the asset cannot load — allows splash to unblock.
  final VoidCallback? onFailed;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.splashFinal,
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.08),
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, sync) {
        if (frame != null || sync) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onPainted?.call();
          });
          return child;
        }
        // Midnight while decoding — removal is gated on onPainted upstream.
        return const ColoredBox(
          color: SplashDestination.midnight,
          child: SizedBox.expand(),
        );
      },
      errorBuilder: (context, error, stack) {
        debugPrint('SPLASH_TIMING FINAL_ART_ERROR $error');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onFailed?.call();
        });
        return const ColoredBox(
          color: SplashDestination.midnight,
          child: SizedBox.expand(),
        );
      },
    );
  }
}

class SplashFinalAtmosphere extends StatelessWidget {
  const SplashFinalAtmosphere({super.key, required this.strength});

  final double strength;

  @override
  Widget build(BuildContext context) {
    final a = (0.07 + 0.05 * strength).clamp(0.0, 0.14);
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.15),
            radius: 1.05,
            colors: [
              const Color(0xFF6B3FA0).withValues(alpha: a),
              Colors.transparent,
            ],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class SplashFinalWordVeil extends StatelessWidget {
  const SplashFinalWordVeil({super.key, required this.strength});

  final double strength;

  @override
  Widget build(BuildContext context) {
    if (strength <= 0.01) return const SizedBox.shrink();
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.center,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              SplashDestination.midnight.withValues(alpha: strength * 0.55),
              SplashDestination.midnight.withValues(alpha: strength),
            ],
            stops: const [0.42, 0.62, 1.0],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
