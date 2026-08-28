/// Circular archive plate — manuscript chamber, never an observatory instrument.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';
import 'star_map_reference_tokens.dart';

class StarMapArchivePlate extends StatelessWidget {
  const StarMapArchivePlate({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: StarMapReferenceTokens.archiveInk,
      child: OraclyAssetImage(
        assetPath: AppAssets.yildiznameHero,
        width: width,
        height: height,
        fit: BoxFit.cover,
        // Keep scholar + moon arch centered in the circular crop.
        alignment: const Alignment(0.02, -0.06),
        filterQuality: FilterQuality.high,
        fallback: ColoredBox(color: StarMapReferenceTokens.archiveInk),
      ),
    );
  }
}
