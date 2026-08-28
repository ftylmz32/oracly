/// Coherent illustrated emblem for one tropical zodiac sign.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/app_icons.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';

class AstrologyZodiacIllustration extends StatelessWidget {
  const AstrologyZodiacIllustration({
    super.key,
    required this.signId,
    this.size,
    this.fit = BoxFit.cover,
  });

  final String signId;
  final double? size;
  final BoxFit fit;

  static String assetFor(String signId) {
    final id = signId.trim().toLowerCase();
    if (AppAssets.zodiacSignIds.contains(id)) {
      return AppAssets.zodiacIllustration(id);
    }
    return AppAssets.zodiacIllustration('aries');
  }

  @override
  Widget build(BuildContext context) {
    final side = size;
    final image = OraclyAssetImage(
      assetPath: assetFor(signId),
      fit: fit,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      fallback: Icon(
        AppIcons.empty,
        color: OraclyChrome.goldLight.withValues(alpha: 0.72),
        size: (side ?? 48) * 0.42,
      ),
    );
    if (side == null) return image;
    return SizedBox(width: side, height: side, child: image);
  }
}
