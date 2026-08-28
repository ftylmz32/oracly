/// Shared gold-framed artwork — deep indigo fill, no warm wash.
library;

import 'package:flutter/material.dart';

import '../../shared/widgets/oracly_asset_image.dart';
import '../theme/app_colors.dart';
import 'app_radius.dart';

/// Displays a provided asset without recoloring, cropping, or distortion.
class OraclyArtFrame extends StatelessWidget {
  const OraclyArtFrame({
    super.key,
    required this.assetPath,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.borderRadius = AppRadius.s24,
    this.padding = const EdgeInsets.all(6),
    this.knockoutBlack = false,
    this.semanticsLabel,
  });

  final String assetPath;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final bool knockoutBlack;
  final String? semanticsLabel;

  static const _indigo = Color(0xFF0A041A);

  static final _knockoutBlack = ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    2.6, 2.6, 2.6, 0, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    Widget art = OraclyAssetImage(
      assetPath: assetPath,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      fallback: Icon(
        Icons.nights_stay_rounded,
        color: AppColors.goldLight.withValues(alpha: 0.88),
      ),
    );

    if (knockoutBlack) {
      art = ColorFiltered(colorFilter: _knockoutBlack, child: art);
    }

    final framed = SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: _indigo,
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.50),
            width: 1.15,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purpleGlow.withValues(alpha: 0.28),
              blurRadius: 18,
            ),
            BoxShadow(
              color: AppColors.goldGlow.withValues(alpha: 0.14),
              blurRadius: 12,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Padding(padding: padding, child: art),
        ),
      ),
    );

    if (semanticsLabel == null) return framed;
    return Semantics(label: semanticsLabel, image: true, child: framed);
  }
}
